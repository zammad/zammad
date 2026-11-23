# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Loads the records of models into the search index, newest first and in turns: every model hands out a batch of
# records per turn, so the newest records of all models are searchable early.
#
#   SearchIndexBackend::Reload.new(Models.indexable, worker: 4).perform do |records|
#     puts "#{records.model} #{records.count}/#{records.total}"
#   end
#
# The workers are not started for every batch: a worker which is free takes the next slice of records, whatever
# model it belongs to.
class SearchIndexBackend::Reload
  # The workers are replaced after this number of records, so the memory a large record leaves behind is given back.
  WORKER_LIFETIME = 10_000

  attr_reader :sources, :worker, :queue, :waiting, :progress

  def initialize(models, worker: 0)
    @worker  = worker
    @sources = models.map { |model| Records.new(model, worker:) }
    @queue   = []
    @waiting = sources.each_index.to_a
  end

  def perform(&progress)
    @progress = progress

    return perform_inline if worker.zero?

    # A worker would load a class when it needs it first, from files which may have been replaced since the start.
    Rails.application.eager_load!

    # The workers share the memory of this process until they change it, and they change less of it when it is tidy.
    Process.warmup

    perform_with_workers while queue.any? || waiting.any?
  end

  private

  def perform_inline
    while (job = next_job)
      index(job)
      done(job)
    end
  end

  def perform_with_workers
    count    = 0
    producer = lambda do
      next Parallel::Stop if count >= WORKER_LIFETIME

      job = ActiveRecord::Base.connection_pool.with_connection { next_job }
      next Parallel::Stop if !job

      count += job.last.size
      job
    end

    # With a finish hook Parallel sends what the block returns to this process and keeps it.
    Parallel.each(producer, in_processes: worker, finish: ->(job, *) { done(job) }) do |job|
      index(job)
      nil
    end
  end

  # A job is the position of a model and the ids of one slice of its records.
  def next_job
    while queue.empty? && waiting.any?
      position = waiting.shift
      source   = sources[position]
      slices   = source.next_slices

      waiting.push(position) if !source.exhausted?
      queue.concat(slices.map { |ids| [position, ids] })

      progress&.call(source) if slices.empty?
    end

    queue.shift
  end

  def index((position, ids))
    sources[position].index(ids)
  end

  def done((position, ids))
    sources[position].done(ids)

    progress&.call(sources[position])
  end
end

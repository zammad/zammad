# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ImportJob < ApplicationModel

  store :payload
  store :result

  scope :running, -> { where(finished_at: nil, dry_run: false).where.not(started_at: nil) }

  # Starts the import backend class based on the name attribute.
  # Import backend class is initialized with the current instance.
  # Logs the start and end time (if ended successfully) and logs
  # exceptions into result if they happen.
  #
  # @example
  #  import = ImportJob.new(name: 'Import::Ldap', payload: Setting.get('ldap_config'))
  #  import.start
  #
  # return [nil]
  def start
    self.started_at = Time.zone.now
    save
    instance = name.constantize.new(self)
    instance.start
  rescue => e
    Rails.logger.error "ImportJob '#{name}' failed: #{e.message}"
    Rails.logger.error e

    # rubocop:disable Style/RedundantSelf
    if !self.result.is_a?(Hash)
      self.result = {}
    end
    self.result[:error] = e.message
    # rubocop:enable Style/RedundantSelf
  ensure
    self.finished_at = Time.zone.now
    save
  end

  # Gets called when the Scheduler gets (re-)started and this job was still
  # in the queue. If `finished_at` is blank the call is piped through to
  # the ImportJob backend which has to decide how to go from here. The delayed
  # job will get destroyed if rescheduled? is not implemented
  # as an ImportJob backend class method.
  #
  # @see Scheduler#cleanup_delayed
  #
  # @example
  #  import.reschedule?(delayed_job)
  #
  # return [Boolean] whether the ImportJob should get rescheduled (true) or destroyed (false)
  def reschedule?(delayed_job)
    return false if finished_at.present?

    instance = name.constantize.new(self)
    return false if !instance.respond_to?(:reschedule?)

    instance.reschedule?(delayed_job)
  end

  # Convenience wrapper around the start method for starting (delayed) dry runs.
  # Logs the start and end time (if ended successfully) and logs
  # exceptions into result if they happen.
  # Only one running or pending dry run per backend is possible at the same time.
  #
  # @param [Hash] params the params used to initialize the ImportJob instance.
  # @option params [Boolean] :delay Defines if job should get executed delayed. Default is true.

  # @example
  #  import = ImportJob.dry_run(name: 'Import::Ldap', payload: Setting.get('ldap_config'), delay: false)
  #
  # return [nil]
  def self.dry_run(params)

    return if exists?(name: params[:name], dry_run: true, finished_at: nil)

    params[:dry_run] = true
    job = create(params.except(:delay))

    if params.fetch(:delay, true)
      AsyncImportJob.perform_later(job)
    else
      job.start
    end
  end

  # Queues and starts all import backends as import jobs.
  #
  # @example
  #  ImportJob.start_registered
  #
  # return [nil]
  def self.start_registered
    queue_registered
    start
  end

  # Starts all import jobs that have not started yet and are no dry runs.
  #
  # @example
  #  ImportJob.start
  #
  # return [nil]
  def self.start
    where(started_at: nil, dry_run: false).each(&:start)
  end

  # Queues all configured import backends from Setting 'import_backends' as import jobs
  # that are not yet queued. Backends which are not #queueable? are skipped.
  #
  # @example
  #  ImportJob.queue_registered
  #
  # return [nil]
  def self.queue_registered
    backends.each do |backend|

      # skip backends that are not "ready" yet
      next if !backend.constantize.queueable?

      # skip if no entry exists
      # skip if a not finished entry exists
      next if ImportJob.exists?(name: backend, finished_at: nil)

      ImportJob.create(name: backend)
    end
  end

  # Checks if the given import backend is valid.
  #
  # @example
  #  ImportJob.backend_valid?('Import::Ldap')
  #  # => true
  #
  # return [Boolean]
  def self.backend_valid?(backend)
    backend.constantize
    true
  rescue NameError
    false
  end

  # Returns a list of valid import backends.
  #
  # @example
  #  ImportJob.backends
  #  # => ['Import::Ldap', 'Import::Exchange', ...]
  #
  # return [Boolean]
  def self.backends
    Setting.get('import_backends')&.select do |backend|

      if !backend_valid?(backend)
        logger.error "Invalid import backend '#{backend}'"
        next
      end

      # skip deactivated backends
      next if !backend.constantize.active?

      true
    end || []
  end
end

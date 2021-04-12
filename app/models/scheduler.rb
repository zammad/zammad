# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Scheduler < ApplicationModel
  include ChecksHtmlSanitized

  extend ::Mixin::StartFinishLogger

  sanitized_html :note

  # rubocop:disable Style/ClassVars
  @@jobs_started = {}
  # rubocop:enable Style/ClassVars

  # start threads
  def self.threads

    Thread.abort_on_exception = true

    # reconnect in case db connection is lost
    begin
      ActiveRecord::Base.connection.reconnect!
    rescue => e
      logger.error "Can't reconnect to database #{e.inspect}"
    end

    # cleanup old background jobs
    cleanup

    # start worker for background jobs
    worker

    # start loop to execute scheduler jobs
    loop do
      logger.info 'Scheduler running...'

      # reconnect in case db connection is lost
      begin
        ActiveRecord::Base.connection.reconnect!
      rescue => e
        logger.error "Can't reconnect to database #{e.inspect}"
      end

      # read/load jobs and check if each has already been started
      jobs = Scheduler.where(active: true).order(prio: :asc)
      jobs.each do |job|

        # ignore job is still running
        next if skip_job?(job)

        # check job.last_run
        next if job.last_run && job.period && job.last_run > (Time.zone.now - job.period)

        # run job as own thread
        @@jobs_started[ job.id ] = start_job(job)
        sleep 10
      end
      sleep 60
    end
  end

  # Checks if a Scheduler Job should get started or not.
  # The decision is based on if there is a running thread or not.
  # Invalid threads get cancelled and new threads can get started.
  #
  # @param [Scheduler] job The job that should get checked for running threads.
  #
  # @example
  #   Scheduler.skip_job(job)
  #
  # return [Boolean]
  def self.skip_job?(job)
    thread = @@jobs_started[ job.id ]
    return false if thread.blank?

    # check for validity of thread instance
    if !thread.respond_to?(:status)
      logger.error "Invalid thread stored for job '#{job.name}' (#{job.method}): #{thread.inspect}. Deleting and resting job."
      @@jobs_started.delete(job.id)
      return false
    end

    # check thread state:
    # http://devdocs.io/ruby~2.4/thread#method-i-status
    status = thread.status

    # non falsly state means it has some literal running state
    if status.present?
      logger.info "Running job thread for '#{job.name}' (#{job.method}) status is: #{status}"
      return true
    end

    # the following cases should not happen since the
    # @@jobs_started cleanup is performed inside of the
    # thread itself
    # therefore we have to log an error and remove it
    # from our threadpool @@jobs_started
    how = 'unknownly'
    if status.nil?
      how = 'via an exception'
    elsif status == false
      how = 'normally'
    end

    logger.error "Job thread terminated #{how} found for '#{job.name}' (#{job.method}). This should not happen. Please report."
    @@jobs_started.delete(job.id)
    false
  end

  # Checks all delayed jobs that are locked and cleans them up.
  # Should only get called when the Scheduler gets started.
  #
  # @see Scheduler#cleanup_delayed
  #
  # @param [Boolean] force forces the cleanup if not called in Scheduler starting context.
  #
  # @example
  #   Scheduler.cleanup
  #
  # @raise [RuntimeError] If called without force and not when Scheduler gets started.
  #
  # return [nil]
  def self.cleanup(force: false)

    if !force && caller_locations(1..1).first.label != 'threads'
      raise 'This method should only get called when Scheduler.threads are initialized. Use `force: true` to start anyway.'
    end

    start_time = Time.zone.now

    cleanup_delayed_jobs(start_time)
    cleanup_import_jobs(start_time)
  end

  # Checks for locked delayed jobs and tries to reschedule or destroy each of them.
  #
  # @param [ActiveSupport::TimeWithZone] after the time the cleanup was started
  #
  # @example
  #   Scheduler.cleanup_delayed_jobs(TimeZone.now)
  #
  # return [nil]
  def self.cleanup_delayed_jobs(after)
    log_start_finish(:info, "Cleanup of left over locked delayed jobs #{after}") do

      Delayed::Job.where('updated_at < ?', after).where.not(locked_at: nil).each do |job|
        log_start_finish(:info, "Checking left over delayed job #{job.inspect}") do
          cleanup_delayed(job)
        end
      end
    end
  end

  # Checks if the given delayed job can be rescheduled or destroys it. Logs the action as warn.
  # Works only for locked delayed jobs. Delayed jobs that are not locked are ignored and
  # should get destroyed directly.
  # Checks the Delayed::Job instance for a method called .reschedule?. The method is called
  # with the Delayed::Job instance as a parameter. The result value is expected to be a Boolean.
  # If the result is true the lock gets removed and the delayed job gets rescheduled.
  # If the return value is false it will get destroyed which is the default behaviour.
  #
  # @param [Delayed::Job] job the job that should get checked for destroying/rescheduling.
  #
  # @example
  #   Scheduler.cleanup_delayed(job)
  #
  # return [nil]
  def self.cleanup_delayed(job)
    return if job.locked_at.blank?

    job_name       = job.name
    payload_object = job.payload_object
    reschedule     = false
    if payload_object.present?
      if payload_object.respond_to?(:object)
        object = payload_object.object

        if object.respond_to?(:id)
          job_name += " (id: #{object.id})"
        end

        if object.respond_to?(:reschedule?) && object.reschedule?(job)
          reschedule = true
        end
      end

      if payload_object.respond_to?(:args)
        job_name += " - ARGS: #{payload_object.args.inspect}"
      end
    end

    if reschedule
      action = 'Rescheduling'
      job.unlock
      job.save
    else
      action = 'Destroyed'
      job.destroy
    end

    logger.warn "#{action} locked delayed job: #{job_name}"
  end

  # Checks for killed import jobs and marks them as finished and adds a note.
  #
  # @param [ActiveSupport::TimeWithZone] after the time the cleanup was started
  #
  # @example
  #   Scheduler.cleanup_import_jobs(TimeZone.now)
  #
  # return [nil]
  def self.cleanup_import_jobs(after)
    log_start_finish(:info, "Cleanup of left over import jobs #{after}") do
      error = 'Interrupted by scheduler restart. Please restart manually or wait till next execution time.'.freeze

      # we need to exclude jobs that were updated at or since we started
      # cleaning up (via the #reschedule? call) because they might
      # were started `.delay`-ed and are flagged for restart
      ImportJob.running.where('updated_at < ?', after).each do |job|

        job.update!(
          finished_at: after,
          result:      {
            error: error
          }
        )
      end
    end
  end

  def self.start_job(job)

    # start job and return thread handle
    Thread.new do
      ApplicationHandleInfo.current = 'scheduler'

      logger.debug { "Started job thread for '#{job.name}' (#{job.method})..." }

      # start loop for periods equal or under 5 minutes
      if job.period && job.period <= 5.minutes
        loop_count = 0
        loop do
          loop_count += 1
          _start_job(job)
          job = Scheduler.lookup(id: job.id)

          # exit is job got deleted
          break if !job

          # exit if job is not active anymore
          break if !job.active

          # exit if there is no loop period defined
          break if !job.period

          # only do a certain amount of loops in this thread
          break if loop_count == 1800

          # wait until next run
          sleep job.period
        end
      else
        _start_job(job)
      end

      if job.present?
        job.pid = ''
        job.save

        logger.debug { " ...stopped thread for '#{job.method}'" }

        # release thread lock and remove thread handle
        @@jobs_started.delete(job.id)
      else
        logger.warn ' ...Job got deleted while running'
      end

      ActiveRecord::Base.connection.close
    end
  end

  def self._start_job(job, try_count = 0, try_run_time = Time.zone.now)
    started_at = Time.zone.now
    job.update!(
      last_run:      started_at,
      pid:           Thread.current.object_id,
      status:        'ok',
      error_message: '',
    )

    logger.info "execute #{job.method} (try_count #{try_count})..."
    eval job.method() # rubocop:disable Security/Eval
    took = Time.zone.now - started_at
    logger.info "ended #{job.method} took: #{took} seconds."
  rescue => e
    took = Time.zone.now - started_at
    logger.error "execute #{job.method} (try_count #{try_count}) exited with error #{e.inspect} in: #{took} seconds."

    # reconnect in case db connection is lost
    begin
      ActiveRecord::Base.connection.reconnect!
    rescue => e
      logger.error "Can't reconnect to database #{e.inspect}"
    end

    try_run_max = 10
    try_count += 1

    # reset error counter if to old
    if try_run_time + (60 * 5) < Time.zone.now
      try_count = 0
    end
    try_run_time = Time.zone.now

    # restart job again
    if try_run_max > try_count
      # wait between retries (see https://github.com/zammad/zammad/issues/1950)
      sleep(try_count) if Rails.env.production?
      _start_job(job, try_count, try_run_time)
    else
      # release thread lock and remove thread handle
      @@jobs_started.delete(job.id)
      error = "Failed to run #{job.method} after #{try_count} tries #{e.inspect}"
      logger.error error

      job.update!(
        error_message: error,
        status:        'error',
        active:        false,
      )
    end

  # rescue any other Exceptions that are not StandardError or childs of it
  # https://stackoverflow.com/questions/10048173/why-is-it-bad-style-to-rescue-exception-e-in-ruby
  # http://rubylearning.com/satishtalim/ruby_exceptions.html
  rescue Exception => e # rubocop:disable Lint/RescueException
    took = Time.zone.now - started_at
    logger.error "execute #{job.method} (try_count #{try_count}) exited with a non standard-error #{e.inspect} in: #{took} seconds."
    raise
  end

  def self.worker(foreground = false)

    # used for tests
    if foreground
      original_interface_handle = ApplicationHandleInfo.current
      ApplicationHandleInfo.current = 'scheduler'

      original_user_id = UserInfo.current_user_id
      UserInfo.current_user_id = nil

      loop do
        success, failure = Delayed::Worker.new.work_off
        if failure.nonzero?
          raise "#{failure} failed background jobs: #{Delayed::Job.where.not(last_error: nil).inspect}"
        end
        break if success.zero?
      end
      UserInfo.current_user_id = original_user_id
      ApplicationHandleInfo.current = original_interface_handle
      return
    end

    # used for production
    wait = 4
    Thread.new do
      sleep wait

      logger.info "Starting worker thread #{Delayed::Job}"

      loop do
        ApplicationHandleInfo.current = 'scheduler'
        result = nil

        realtime = Benchmark.realtime do
          logger.debug { "*** worker thread, #{Delayed::Job.all.count} in queue" }
          result = Delayed::Worker.new.work_off
        end

        count = result.sum

        if count.zero?
          sleep wait
          logger.debug { '*** worker thread loop' }
        else
          format "*** #{count} jobs processed at %<jps>.4f j/s, %<failed>d failed ...\n", jps: count / realtime, failed: result.last
        end
      end

      logger.info ' ...stopped worker thread'
      ActiveRecord::Base.connection.close
    end

  end

  # This function returns a list of failed jobs
  #
  # @example
  #   Scheduler.failed_jobs
  #
  # return [Array]
  def self.failed_jobs
    where(status: 'error', active: false)
  end

  # This function restarts failed jobs to retry them
  #
  # @example
  #   Scheduler.restart_failed_jobs
  #
  # return [true]
  def self.restart_failed_jobs
    failed_jobs.each do |job|
      job.update!(active: true)
    end

    true
  end

end

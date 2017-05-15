# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Scheduler < ApplicationModel

  # rubocop:disable Style/ClassVars
  @@jobs_started = {}
  # rubocop:enable Style/ClassVars

  # start threads
  def self.threads

    Thread.abort_on_exception = true

    # reconnect in case db connection is lost
    # See issue #1080
    begin
      ActiveRecord::Base.connection.reconnect!
    rescue PG::UnableToSend => e # rubocop:disable Lint/HandleExceptions
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

      # read/load jobs and check if it is alredy started
      jobs = Scheduler.where('active = ?', true).order('prio ASC')
      jobs.each { |job|

        # ignore job is still running
        next if @@jobs_started[ job.id ]

        # check job.last_run
        next if job.last_run && job.period && job.last_run > (Time.zone.now - job.period)

        # run job as own thread
        @@jobs_started[ job.id ] = true
        start_job(job)
        sleep 10
      }
      sleep 60
    end
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

    if !force && caller_locations.first.label != 'threads'
      raise 'This method should only get called when Scheduler.threads are initialized. Use `force: true` to start anyway.'
    end

    Delayed::Job.all.each do |job|
      cleanup_delayed(job)
    end
  end

  # Checks if the given job can be rescheduled or destroys it. Logs the action as warn.
  # Works only for locked jobs. Jobs that are not locked are ignored and
  # should get destroyed directly.
  # Checks the delayed job object for a method called .reschedule?. The memthod is called
  # with the delayed job as a parameter. The result value is expected as a Boolean. If the
  # result is true the lock gets removed and the delayed job gets rescheduled. If the return
  # value is false it will get destroyed which is the default behaviour.
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

    Rails.logger.warn "#{action} locked delayed job: #{job_name}"
  end

  def self.start_job(job)

    Thread.new {
      ApplicationHandleInfo.current = 'scheduler'

      logger.info "Started job thread for '#{job.name}' (#{job.method})..."

      # start loop for periods under 5 minutes
      if job.period && job.period <= 300
        loop do
          _start_job(job)
          job = Scheduler.lookup(id: job.id)

          # exit is job got deleted
          break if !job

          # exit if job is not active anymore
          break if !job.active

          # exit if there is no loop period defined
          break if !job.period

          # wait until next run
          sleep job.period
        end
      else
        _start_job(job)
      end
      job.pid = ''
      job.save
      logger.info " ...stopped thread for '#{job.method}'"
      ActiveRecord::Base.connection.close

      # release thread lock
      @@jobs_started[ job.id ] = false
    }
  end

  def self._start_job(job, try_count = 0, try_run_time = Time.zone.now)
    job.last_run = Time.zone.now
    job.pid      = Thread.current.object_id
    job.save
    logger.info "execute #{job.method} (try_count #{try_count})..."
    eval job.method() # rubocop:disable Lint/Eval
  rescue => e
    logger.error "execute #{job.method} (try_count #{try_count}) exited with error #{e.inspect}"

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
      _start_job(job, try_count, try_run_time)
    else
      raise "STOP thread for #{job.method} after #{try_count} tries (#{e.inspect})"
    end
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
          raise "ERROR: #{failure} failed background jobs: #{Delayed::Job.where('last_error IS NOT NULL').inspect}"
        end
        break if success.zero?
      end
      UserInfo.current_user_id = original_user_id
      ApplicationHandleInfo.current = original_interface_handle
      return
    end

    # used for production
    wait = 8
    Thread.new {
      sleep wait

      logger.info "Starting worker thread #{Delayed::Job}"

      loop do
        ApplicationHandleInfo.current = 'scheduler'
        result = nil

        realtime = Benchmark.realtime do
          logger.debug "*** worker thread, #{Delayed::Job.all.count} in queue"
          result = Delayed::Worker.new.work_off
        end

        count = result.sum

        if count.zero?
          sleep wait
          logger.debug '*** worker thread loop'
        else
          format "*** #{count} jobs processed at %.4f j/s, %d failed ...\n", count / realtime, result.last
        end
      end

      logger.info ' ...stopped worker thread'
      ActiveRecord::Base.connection.close
    }

  end

end

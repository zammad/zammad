# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Scheduler < ApplicationModel

  # rubocop:disable Style/ClassVars
  @@jobs_started = {}
  # rubocop:enable Style/ClassVars

  # start threads
  def self.threads

    Thread.abort_on_exception = true

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

  def self.start_job(job)

    Thread.new {

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
      raise "STOP thread for #{job.method} after #{try_count} tries"
    end
  end

  def self.worker(foreground = false)

    # used for tests
    if foreground
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
      return
    end

    # used for production
    wait = 8
    Thread.new {
      sleep wait

      logger.info "Starting worker thread #{Delayed::Job}"

      loop do
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

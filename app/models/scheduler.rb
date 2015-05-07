# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
# rubocop:disable Rails/Output
class Scheduler < ApplicationModel

  def self.run( runner, runner_count )

    Thread.abort_on_exception = true

    jobs_started = {}
    loop do
      logger.info "Scheduler running (runner #{runner} of #{runner_count})..."

      # reconnect in case db connection is lost
      begin
        ActiveRecord::Base.connection.reconnect!
      rescue => e
        logger.error "Can't reconnect to database #{ e.inspect }"
      end

      # read/load jobs and check if it is alredy started
      jobs = Scheduler.where( 'active = ? AND prio = ?', true, runner )
      jobs.each {|job|
        next if jobs_started[ job.id ]
        jobs_started[ job.id ] = true
        start_job( job, runner, runner_count )
      }
      sleep 90
    end
  end

  def self.start_job( job, runner, runner_count )
    logger.info "started job thread for '#{job.name}' (#{job.method})..."
    sleep 4

    Thread.new {
      if job.period
        loop do
          _start_job( job, runner, runner_count )
          job = Scheduler.lookup( id: job.id )

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
        _start_job( job, runner, runner_count )
      end
      #        raise "Exception from thread"
      job.pid = ''
      job.save
      logger.info " ...stopped thread for '#{job.method}'"
      ActiveRecord::Base.connection.close
    }
  end

  def self._start_job( job, runner, runner_count, try_count = 0, try_run_time = Time.now )
    sleep 5
    begin
      job.last_run = Time.now
      job.pid = Thread.current.object_id
      job.save
      logger.info "execute #{job.method} (runner #{runner} of #{runner_count}, try_count #{try_count})..."
      eval job.method()
    rescue => e
      logger.error "execute #{job.method} (runner #{runner} of #{runner_count}, try_count #{try_count}) exited with error #{ e.inspect }"

      # reconnect in case db connection is lost
      begin
        ActiveRecord::Base.connection.reconnect!
      rescue => e
        logger.error "Can't reconnect to database #{ e.inspect }"
      end

      try_run_max = 10
      try_count += 1

      # reset error counter if to old
      if try_run_time + ( 60 * 5 ) < Time.now
        try_count = 0
      end
      try_run_time = Time.now

      # restart job again
      if try_run_max > try_count
        _start_job( job, runner, runner_count, try_count, try_run_time)
      else
        raise "STOP thread for #{job.method} (runner #{runner} of #{runner_count} after #{try_count} tries"
      end
    end
  end

  def self.worker
    wait = 10
    logger.info "*** Starting worker #{Delayed::Job}"

    loop do
      result = nil

      realtime = Benchmark.realtime do
        result = Delayed::Worker.new.work_off
      end

      count = result.sum

      break if $exit

      if count.zero?
        sleep(wait)
        logger.info '*** worker loop'
      else
        format "*** #{count} jobs processed at %.4f j/s, %d failed ...\n", count / realtime, result.last
      end
    end
  end

  def self.check( name, time_warning = 10, time_critical = 20 )
    time_warning_time  = Time.now - time_warning.minutes
    time_critical_time = Time.now - time_critical.minutes
    scheduler = Scheduler.find_by( name: name )
    if !scheduler
      puts "CRITICAL - no such scheduler jobs '#{name}'"
      return true
    end
    logger.debug scheduler.inspect
    if !scheduler.last_run
      puts "CRITICAL - scheduler jobs never started '#{name}'"
      exit 2
    end
    if scheduler.last_run < time_critical_time
      puts "CRITICAL - scheduler jobs was not running in last '#{time_critical}' minutes - last run at '#{scheduler.last_run}' '#{name}'"
      exit 2
    end
    if scheduler.last_run < time_warning_time
      puts "CRITICAL - scheduler jobs was not running in last '#{time_warning}' minutes - last run at '#{scheduler.last_run}' '#{name}'"
      exit 2
    end
    puts "ok - scheduler jobs was running at '#{scheduler.last_run}' '#{name}'"
    exit 0
  end
end

# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Scheduler < ApplicationModel

  def self.run( worker, worker_count )

    Thread.abort_on_exception = true

    jobs_started = {}
    while true
      puts "Scheduler running (worker #{worker} of #{worker_count})..."

      # read/load jobs and check if it is alredy started
      jobs = Scheduler.where( 'active = ? AND prio = ?', true, worker )
      jobs.each {|job|
        next if jobs_started[ job.id ]
        jobs_started[ job.id ] = true
        self.start_job( job, worker, worker_count )
      }
      sleep 45
    end
  end

  def self.start_job( job, worker, worker_count )
    puts "started job thread for '#{job.name}' (#{job.method})..."
    sleep 4

    Thread.new {
      if job.period
        while true
          self._start_job( job, worker, worker_count )
          job = Scheduler.where( :id => job.id ).first

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
        self._start_job( job, worker, worker_count )
      end
      #        raise "Exception from thread"
      job.pid = ''
      job.save
      puts " ...stopped thread for '#{job.method}'"
    }
  end

  def self._start_job( job, worker, worker_count )
    puts "execute #{job.method} (worker #{worker} of #{worker_count})..."
    job.last_run = Time.now
    job.pid = Thread.current.object_id
    job.save
    eval job.method()
  end

  def self.check( name, time_warning = 10, time_critical = 20 )
    time_warning_time  = Time.now - time_warning.minutes
    time_critical_time = Time.now - time_critical.minutes
    scheduler = Scheduler.where( :name => name ).first
    if !scheduler
      puts "CRITICAL - no such scheduler jobs '#{name}'"
      return true
    end
#puts "S " + scheduler.inspect
    if !scheduler.last_run
      puts "CRITICAL - scheduler jobs never started '#{name}'"
      exit 2
    end
    if scheduler.last_run < time_critical_time
      puts "CRITICAL - scheduler jobs was not running in last '#{time_critical.to_s}' minutes - last run at '#{scheduler.last_run.to_s}' '#{name}'"
      exit 2
    end
    if scheduler.last_run < time_warning_time
      puts "CRITICAL - scheduler jobs was not running in last '#{time_warning.to_s}' minutes - last run at '#{scheduler.last_run.to_s}' '#{name}'"
      exit 2
    end
    puts "ok - scheduler jobs was running at '#{scheduler.last_run.to_s}' '#{name}'"
    exit 0
  end
end

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
    puts "execute #{job.method}..."
    job.last_run = Time.now
    job.pid = Thread.current.object_id
    job.save
    puts "execute #{job.method} (worker #{worker} of #{worker_count})..."
    eval job.method()
  end
end
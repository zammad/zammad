class Scheduler < ApplicationModel

  def self.run

    Thread.abort_on_exception = true
  
    # read/load jobs
    jobs = Scheduler.where( :active => true )
    jobs.each {|job|
      self.start_job( job )
    }
    while true
      puts 'Scheduler running...'
      sleep 60
    end
  end

  def self.start_job(job)
    puts "started job thread for '#{job.name}' (#{job.method})..."
    sleep 1.5

    Thread.new {
      if job.period
        while true
          self._start_job(job)
          job = Scheduler.where( :id => job.id ).first
          break if !job
          break if !job.active
          break if !job.period
          sleep job.period
        end
      else
        self._start_job(job)
      end
#        raise "Exception from thread"
      job.pid = ''
      job.save
      puts " ...stopped thread for '#{job.method}'"
    }
  end

  def self._start_job(job)
    puts "execute #{job.method}..."
    job.last_run = Time.now
    job.pid = Thread.current.object_id
    job.save
    eval job.method
  end
end
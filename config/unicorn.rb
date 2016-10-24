worker_processes ENV['UNICORN_WORKER'].to_i
working_directory "#{ENV['UNICORN_DIR']}"

timeout ENV['UNICORN_TIMEOUT'].to_i

# Specify path to socket unicorn listens to,
# we will use this in our nginx.conf later
listen "#{ENV['RAILS_SOCKET_DIR']}/unicorn.sock", :backlog => 64

# Set process id path
pid "#{ENV['RAILS_PID_DIR']}/unicorn.pid"

# Set log file paths
stderr_path "#{ENV['RAILS_LOG_DIR']}/unicorn_error.log"
stdout_path "#{ENV['RAILS_LOG_DIR']}/unicorn_access.log"

before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = "#{ENV['RAILS_PID_DIR']}/unicorn.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end


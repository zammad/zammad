APP_DIR="."
UNICORN_DIR="#{APP_DIR}"
UNICORN_WORKER="4"
UNICORN_TIMEOUT="30"
RAILS_PID_DIR="#{APP_DIR}/tmp/pids"
RAILS_LOG_DIR="#{APP_DIR}/log"

worker_processes UNICORN_WORKER.to_i
working_directory UNICORN_DIR
timeout UNICORN_TIMEOUT.to_i
pid "#{RAILS_PID_DIR}/unicorn.pid"
stderr_path "#{RAILS_LOG_DIR}/unicorn_error.log"
stdout_path "#{RAILS_LOG_DIR}/unicorn_access.log"

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

  old_pid = "#{RAILS_PID_DIR}/unicorn.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

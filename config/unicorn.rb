# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

worker_processes 4
timeout 30
stderr_path 'log/unicorn_error.log'
stdout_path 'log/unicorn_access.log'
pid 'tmp/pids/unicorn.pid'

before_fork do |server, _worker|
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

  old_pid = 'tmp/pids/unicorn.pid.oldbin'
  if File.exist?(old_pid) && server.pid != old_pid
    begin
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      logger.info 'Unicorn master already killed. Someone else did our job for us.'
    end
  end
end

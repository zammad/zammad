# :stopdoc:
#
# Because of the global interpreter lock, Kernel#fork is the best way
# to achieve true concurrency in Ruby scripts. However, there are peculiarities
# when using fork and passing file descriptors between process. These
# peculiarities affect the logging framework.
#
# In short, always reopen file descriptors in the child process after fork has
# been called. The RollingFile appender uses flock to safely coordinate the
# rolling of the log file when multiple processes are writing to the same
# file. If the file descriptor is opened in the parent and multiple children
# are forked, then each child will use the same file descriptor lock; when one
# child locks the file any other child will also have the lock. This creates a
# race condition in the rolling code. The solution is to reopen the file to
# obtain a new file descriptor in each of the children.
#

  require 'logging'

  log = Logging.logger['example']
  log.add_appenders(
      Logging.appenders.rolling_file('roller.log', :age => 'daily')
  )
  log.level = :debug

  # Create four child processes and reopen the "roller.log" file descriptor in
  # each child. Now log rolling will work safely.
  4.times do
    fork {
      Logging.reopen
      log.info "This is child process #{Process.pid}"
    }
  end

  log.info "This is the parent process #{Process.pid}"

# :startdoc:

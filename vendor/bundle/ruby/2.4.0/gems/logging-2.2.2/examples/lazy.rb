# :stopdoc:
#
# It happens sometimes that it is very expensive to construct a logging
# message; for example, if a large object structure has to be traversed
# during execution of an `object.to_s` method. It would be convenient to
# delay creation of the message until the log event actually takes place.
#
# For example, with a logger configured only to show WARN messages and higher,
# creating the log message for an INFO message would be wasteful. The INFO log
# event would never be generated in this case.
#
# Log message creation can be performed lazily by wrapping the expensive
# message generation code in a block and passing that to the logging method.

  require 'logging'

  Logging.logger.root.appenders = Logging.appenders.stdout
  Logging.logger.root.level = :info

  # We use this dummy method in order to see if the method gets called, but in practice,
  # this method might do complicated string operations to construct a log message.
  def expensive_method
    puts "Called!"
    "Expensive message"
  end

  log = Logging.logger['Lazy']

  # If you log this message the usual way, expensive_method gets called before
  # debug, hence the Logging framework has no chance to stop it from being executed
  # immediately.
  log.info("Normal")
  log.debug(expensive_method)

  # If we put the message into a block, then the block is not executed, if
  # the message is not needed with the current log level.
  log.info("Block unused")
  log.debug { expensive_method }

  # If the log message is needed with the current log level, then the block is of
  # course executed and the log message appears as expected.
  log.info("Block used")
  log.warn { expensive_method }

# :startdoc:

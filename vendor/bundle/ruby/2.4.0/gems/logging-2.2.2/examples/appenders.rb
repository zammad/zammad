# :stopdoc:
#
# Appenders are used to output log events to some logging destination. The
# same log event can be sent to multiple desitnations by associating
# multiple appenders with the logger.
#
# The following is a list of all the available appenders and a brief
# description of each. Please refer to the documentation for specific
# configuration options available for each.
#
#   File          writes to a regular file
#   IO            generic IO appender
#   RollingFile   writes to a file and rolls based on size or age
#   Stdout        appends to STDOUT
#   Stderr        appends to STDERR
#   StringIo      writes to a StringIO instance (useful for testing)
#   Syslog        outputs to syslogd (not available on all systems)
#
# And you can access these appenders:
#
#   Logging.appenders.file
#   Logging.appenders.io
#   Logging.appenders.rolling_file
#   Logging.appenders.stdout
#   Logging.appenders.stderr
#   Logging.appenders.string_io
#   Logging.appenders.syslog
#

  require 'logging'

  log = Logging.logger['example']
  log.add_appenders(
      Logging.appenders.stdout,
      Logging.appenders.file('development.log')
  )
  log.level = :debug

  # These messages will be logged to both the log file and to STDOUT
  log.debug "a very nice little debug message"
  log.warn "this is your last warning"

# :startdoc:

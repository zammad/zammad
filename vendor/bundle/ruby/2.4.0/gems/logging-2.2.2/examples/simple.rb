# :stopdoc:
#
# Logging provides a simple, default logger configured in the same manner as
# the default Ruby Logger class -- i.e. the output of the two will be the
# same. All log messages at "warn" or higher are printed to STDOUT; any
# message below the "warn" level are discarded.
#

  require 'logging'

  log = Logging.logger(STDOUT)
  log.level = :warn

  log.debug "this debug message will not be output by the logger"
  log.warn "this is your last warning"

# :startdoc:

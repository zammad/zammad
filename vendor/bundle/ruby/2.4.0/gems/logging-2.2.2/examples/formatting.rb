# :stopdoc:
#
# Any Ruby object can be passed to the log methods of a logger. How these
# objects are formatted by the Logging framework is controlled by a global
# "format_as" option and a global "backtrace" option.
#
# The format_as option allows objects to be converted to a string using the
# standard "to_s" method, the "inspect" method, the "to_json" method, or the
# "to_yaml" method (this is independent of the YAML layout). The format_as
# option can be overridden by each layout as desired.
#
#   Logging.format_as :string   # or :inspect or :json or :yaml
#
# Exceptions are treated differently by the logging framework. The Exception
# class is printed along with the message. Optionally, the exception backtrace
# can be included in the logging output; this option is enabled by default.
#
#   Logging.backtrace false
#
# The backtrace can be enabled or disabled for each layout as needed.
#

  require 'logging'

  Logging.format_as :inspect
  Logging.backtrace false

  Logging.appenders.stdout(
    :layout => Logging.layouts.basic(:format_as => :yaml)
  )

  Logging.appenders.stderr(
    :layout => Logging.layouts.basic(:backtrace => true)
  )

  log = Logging.logger['foo']
  log.appenders = %w[stdout stderr]

  # these log messages will all appear twice because of the two appenders -
  # STDOUT and STDERR - but the interesting thing is the difference in the
  # output
  log.info %w[An Array Of Strings]
  log.info({"one"=>1, "two"=>2})

  begin
    1 / 0
  rescue => err
    log.error err
  end

# :startdoc:

# :stopdoc:
#
# The formatting of log messages is controlled by the layout given to the
# appender. By default all appenders use the Basic layout. It's pretty
# basic. However, a more sophisticated Pattern layout can be used or one of
# the Parseable layouts -- JSON or YAML.
#
# The available layouts are:
#
#   Logging.layouts.basic
#   Logging.layouts.pattern
#   Logging.layouts.json
#   Logging.layouts.yaml
#
# In this example we'll demonstrate use of different layouts and setting log
# levels in the appenders to filter out events.
#

  require 'logging'

  # only show "info" or higher messages on STDOUT using the Basic layout
  Logging.appenders.stdout(:level => :info)

  # send all log events to the development log (including debug) as JSON
  Logging.appenders.rolling_file(
    'development.log',
    :age    => 'daily',
    :layout => Logging.layouts.json
  )

  log = Logging.logger['Foo::Bar']
  log.add_appenders 'stdout', 'development.log'
  log.level = :debug

  log.debug "a very nice little debug message"
  log.info "things are operating normally"
  log.warn "this is your last warning"
  log.error StandardError.new("something went horribly wrong")
  log.fatal "I Die!"

# :startdoc:

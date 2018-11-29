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
# After you configure a layout, you can reuse that layout among different
# appenders if you so choose. This enables you to have some the style of log
# output being sent to multiple destinations.
#
# We will store a Layout instance in a local variable, and then pass that
# instance to each appender.
#

  require 'logging'

  # create our pattern layout instance
  layout = Logging.layouts.pattern \
    :pattern      => '[%d] %-5l %c: %m\n',
    :date_pattern => '%Y-%m-%d %H:%M:%S'

  # only show "info" or higher messages on STDOUT using our layout
  Logging.appenders.stdout \
    :level  => :info,
    :layout => layout

  # send all log events to the development log (including debug) using our layout
  Logging.appenders.rolling_file \
    'development.log',
    :age    => 'daily',
    :layout => layout

  log = Logging.logger['Foo::Bar']
  log.add_appenders 'stdout', 'development.log'
  log.level = :debug

  log.debug "a very nice little debug message"
  log.info "things are operating normally"
  log.warn "this is your last warning"
  log.error StandardError.new("something went horribly wrong")
  log.fatal "I Die!"

# :startdoc:

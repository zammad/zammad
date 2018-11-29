# :stopdoc:
#
# The Pattern layout can colorize log events based on a provided color scheme.
# The configuration is a two part process. First the color scheme is defined
# with the level colors and any pattern token colors. This color scheme is
# then passed by name to the Pattern layout when it is created.
#
# The color scheme defines colors to be applied to the level token found in
# the pattern layout. So that the "info" level will have one color, and the
# "fatal" level will have a separate color. This applies only to the level
# token in the Pattern layout.
#
# Common tokens can have their own color, too. The date token can be colored
# blue, and the message token can be colored magenta.
#
# Colorization should only be applied to TTY logging destinations like STDOUT
# and STDERR. Inserting color codes into a log file is generally considered
# bad form; these color codes cause issues for some command line programs like
# "less" and "more".
#
# A 'default" color scheme is provided with the Logging framework. In the
# example below we create our own color scheme called 'bright' and apply it to
# the 'stdout' appender.
#

  require 'logging'

  # here we setup a color scheme called 'bright'
  Logging.color_scheme( 'bright',
    :levels => {
      :info  => :green,
      :warn  => :yellow,
      :error => :red,
      :fatal => [:white, :on_red]
    },
    :date => :blue,
    :logger => :cyan,
    :message => :magenta
  )

  Logging.appenders.stdout(
    'stdout',
    :layout => Logging.layouts.pattern(
      :pattern => '[%d] %-5l %c: %m\n',
      :color_scheme => 'bright'
    )
  )

  log = Logging.logger['Happy::Colors']
  log.add_appenders 'stdout'
  log.level = :debug

  # these log messages will be nicely colored
  # the level will be colored differently for each message
  #
  log.debug "a very nice little debug message"
  log.info "things are operating nominally"
  log.warn "this is your last warning"
  log.error StandardError.new("something went horribly wrong")
  log.fatal "I Die!"

# :startdoc:

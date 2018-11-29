# :stopdoc:
#
# It's useful to define custom log levels that denote success, or otherwise
# meaningful events that happen to not be negative (more than 50% of the
# levels are given to warn, error, fail - quite a pessimistic view of one's
# application's chances of success, no?  ;-) )
#
# Here, we define two new levels, 'happy' and 'success' and make them soothing
# colours.
#

  require 'logging'

  # https://github.com/TwP/logging/blob/master/lib/logging.rb#L250-285
  # The levels run from lowest level to highest level.

  Logging.init :debug, :info, :happy, :warn, :success, :error, :fatal

  Logging.color_scheme( 'soothing_ish',
    :levels => {
      :info  => :cyan,
      :happy => :green,
      :warn  => :yellow,
      :success => [:blue],
      :error => :red,
      :fatal => [:white, :on_red]
    },
    :date => :cyan,
    :logger => :cyan,
    :message => :orange
  )

  Logging.appenders.stdout(
    'stdout',
    :layout => Logging.layouts.pattern(
      :pattern => '[%d] %-7l %c: %m\n',
      :color_scheme => 'soothing_ish'
    )
  )

  log = Logging.logger['Soothing::Colors']
  log.add_appenders 'stdout'
  log.level = :debug

  log.debug   'a very nice little debug message'
  log.info    'things are operating nominally'
  log.happy   'What a beautiful day'
  log.warn    'this is your last warning'
  log.success 'I am INWEENCIBLE!!'
  log.error   StandardError.new('something went horribly wrong')
  log.fatal   'I Die!'

# :startdoc:

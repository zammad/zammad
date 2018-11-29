# :stopdoc:
#
# Loggers and appenders can be looked up by name. The bracket notation is
# used to find these objects:
#
#   Logging.logger['foo']
#   Logging.appenders['bar']
#
# A logger will be created if a new name is used. Appenders are different;
# nil is returned when an unknown appender name is used. The reason for this
# is that appenders come in many different flavors (so it is unclear which
# type should be created), but there is only one type of logger.
#
# So it is useful to be able to create an appender and then reference it by
# name to add it to multiple loggers. When the same name is used, the same
# object will be returned by the bracket methods.
#
# Layouts do not have names. Some are stateful, and none are threadsafe. So
# each appender is configured with it's own layout.
#

  require 'logging'

  Logging.appenders.file('Debug File', :filename => 'debug.log')
  Logging.appenders.stderr('Standard Error', :level => :error)

  # configure the root logger
  Logging.logger.root.appenders = 'Debug File'
  Logging.logger.root.level = :debug

  # add the Standard Error appender to the Critical logger (it will use it's
  # own appender and the root logger's appender, too)
  Logging.logger['Critical'].appenders = 'Standard Error'

  # if you'll notice above, assigning appenders using just the name is valid
  # the logger is smart enough to figure out it was given a string and then
  # go lookup the appender by name

  # and now log some messages
  Logging.logger['Critical'].info 'just keeping you informed'
  Logging.logger['Critical'].fatal 'WTF!!'

# :startdoc:

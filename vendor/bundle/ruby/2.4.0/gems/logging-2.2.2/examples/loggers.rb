# :stopdoc:
#
# Multiple loggers can be created and each can be configured with it's own
# log level and appenders. So one logger can be configured to output debug
# messages, and all the others can be left at the info or warn level. This
# makes it easier to debug specific portions of your code.
#

  require 'logging'

  # all loggers inherit the log level of the "root" logger
  # but specific loggers can be given their own level
  Logging.logger.root.level = :warn

  # similarly, the root appender will be used by all loggers
  Logging.logger.root.appenders = Logging.appenders.file('output.log')

  log1 = Logging.logger['Log1']
  log2 = Logging.logger['Log2']
  log3 = Logging.logger['Log3']

  # you can use strings or symbols to set the log level
  log3.level = 'debug'

  log1.info "this message will not get logged"
  log2.info "nor will this message"
  log3.info "but this message will get logged"

# :startdoc:

# :stopdoc:
#
# Rails 4 allows you to hook up multiple loggers (even those external to this gem)
# so you can use a single Rails.logger statement. For Rails developers, this is
# easier because if you ever change logging frameworks, you don't have to change
# all of your app code.
#
# See http://railsware.com/blog/2014/08/07/rails-logging-into-several-backends/
#

require 'logging'

log = Logging.logger(STDOUT)
log.level = :warn

Rails.logger.extend(ActiveSupport::Logger.broadcast(log))

Rails.logger.debug "this debug message will not be output by the logger"
Rails.logger.warn "this is your last warning"

# :startdoc:

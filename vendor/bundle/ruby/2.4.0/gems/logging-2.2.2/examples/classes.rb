# :stopdoc:
#
# The Logging framework is very good about figuring out predictable names
# for loggers regardless of what object is used to create them. The name is
# the class name or module name of whatever is passed to the logger bracket
# method. The following lines all return the exact same logger instance:
#
#    ary = Array.new
#    Logging.logger[ary]
#    Logging.logger[Array]
#    Logging.logger['Array']
#    Logging.logger[:Array]
#
# So, if you want each class to have it's own logger this is very easy to
# do.
#

  require 'logging'

  Logging.logger.root.appenders = Logging.appenders.stdout
  Logging.logger.root.level = :info

  class Foo
    attr_reader :log
    def initialize() @log = Logging.logger[self]; end
  end

  class Foo::Bar
    attr_reader :log
    def initialize() @log = Logging.logger[self]; end
  end

  foo = Foo.new.log
  bar = Foo::Bar.new.log

  # you'll notice in these log messages that the logger names were taken
  # from the class names of the Foo and Foo::Bar instances
  foo.info 'this message came from Foo'
  bar.warn 'this is a warning from Foo::Bar'

# :startdoc:

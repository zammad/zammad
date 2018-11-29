# :stopdoc:
#
# Loggers exist in a hierarchical relationship defined by their names. Each
# logger has a parent (except for the root logger). A logger can zero or
# more children. This parent/child relationship is determined by the Ruby
# namespace separator '::'.
#
#   root
#   |-- Foo
#   |   |-- Foo::Bar
#   |   `-- Foo::Baz
#   |-- ActiveRecord
#   |   `-- ActiveRecord::Base
#   |-- ActiveSupport
#   |   `-- ActiveSupport::Base
#   `-- Rails
#
# A logger inherits its log level from its parent. This level can be set for
# each logger in the system. Setting the level on a logger affects all it's
# children and grandchildren, etc. unless the child has it's own level set.
#
# Loggers also have a property called "additivity", and by default it is set
# to true for all loggers. This property enables a logger to pass log events
# up to its parent.
#
# If a logger does not have an appender and its additivity is true, it will
# pass all log events up to its parent who will then try to send the log
# event to its appenders. The parent will do the same thing, passing the log
# event up the chain till the root logger is reached or some parent logger
# has its additivity set to false.
#
# So, if the root logger is the only one with an appender, all loggers can
# still output log events to the appender because of additivity. A logger
# will ALWAYS send log events to its own appenders regardless of its
# additivity.
#
# The show_configuration method can be used to dump the logging hierarchy.
#

  require 'logging'

  Logging.logger.root.level = :debug

  foo = Logging.logger['Foo']
  bar = Logging.logger['Foo::Bar']
  baz = Logging.logger['Foo::Baz']

  # configure the Foo logger
  foo.level = 'warn'
  foo.appenders = Logging.appenders.stdout

  # since Foo is the parent of Foo::Bar and Foo::Baz, these loggers all have
  # their level set to warn

  foo.warn 'this is a warning, not a ticket'
  bar.info 'this message will not be logged'
  baz.info 'nor will this message'
  bar.error 'but this error message will be logged'

  # let's demonstrate additivity of loggers

  Logging.logger.root.appenders = Logging.appenders.stdout

  baz.warn 'this message will be logged twice - once by Foo and once by root'

  foo.additive = false
  bar.warn "foo is no longer passing log events up to it's parent"

  # let's look at the logger hierarchy
  puts '='*76
  Logging.show_configuration

# :startdoc:

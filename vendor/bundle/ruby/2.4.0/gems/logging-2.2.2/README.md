## Logging
by Tim Pease [![](https://secure.travis-ci.org/TwP/logging.svg)](https://travis-ci.org/TwP/logging)

* [Homepage](http://rubygems.org/gems/logging)
* [Github Project](https://github.com/TwP/logging)

### Description

**Logging** is a flexible logging library for use in Ruby programs based on the
design of Java's log4j library. It features a hierarchical logging system,
custom level names, multiple output destinations per log event, custom
formatting, and more.

### Installation

```
gem install logging
```

### Examples

This example configures a logger to output messages in a format similar to the
core ruby Logger class. Only log messages that are warnings or higher will be
logged.

```ruby
require 'logging'

logger = Logging.logger(STDOUT)
logger.level = :warn

logger.debug "this debug message will not be output by the logger"
logger.warn "this is your last warning"
```

In this example, a single logger is created that will append to STDOUT and to a
file. Only log messages that are informational or higher will be logged.

```ruby
require 'logging'

logger = Logging.logger['example_logger']
logger.level = :info

logger.add_appenders \
    Logging.appenders.stdout,
    Logging.appenders.file('example.log')

logger.debug "this debug message will not be output by the logger"
logger.info "just some friendly advice"
```

The Logging library was created to allow each class in a program to have its
own configurable logger. The logging level for a particular class can be
changed independently of all other loggers in the system. This example shows
the recommended way of accomplishing this.

```ruby
require 'logging'

Logging.logger['FirstClass'].level = :warn
Logging.logger['SecondClass'].level = :debug

class FirstClass
  def initialize
    @logger = Logging.logger[self]
  end

  def some_method
    @logger.debug "some method was called on #{self.inspect}"
  end
end

class SecondClass
  def initialize
    @logger = Logging.logger[self]
  end

  def another_method
    @logger.debug "another method was called on #{self.inspect}"
  end
end
```

There are many more examples in the [examples folder](/examples) of the logging
package. The recommended reading order is the following:

* [simple.rb](/examples/simple.rb)
* [rspec_integration.rb](/examples/rspec_integration.rb)
* [loggers.rb](/examples/loggers.rb)
* [classes.rb](/examples/classes.rb)
* [hierarchies.rb](/examples/hierarchies.rb)
* [names.rb](/examples/names.rb)
* [lazy.rb](/examples/lazy.rb)
* [appenders.rb](/examples/appenders.rb)
* [layouts.rb](/examples/layouts.rb)
* [reusing_layouts.rb](/examples/reusing_layouts.rb)
* [formatting.rb](/examples/formatting.rb)
* [colorization.rb](/examples/colorization.rb)
* [fork.rb](/examples/fork.rb)
* [mdc.rb](/examples/mdc.rb)

### Extending

The Logging framework is extensible via the [little-plugger](https://github.com/twp/little-plugger)
gem based plugin system. New appenders or formatters can be released as ruby
gems. When installed locally, the Logging framework will automatically detect
these gems as plugins and make them available for use.

The [logging-email](https://github.com/twp/logging-email) plugin is a good
example to follow. It includes a [`lib/logging/plugins/email.rb`](https://github.com/twp/logging-email/tree/master/lib/logging/plugins/email.rb)
file which is detected by the plugin framework. This file declares a
`Logging::Plugins::Email.initialize_email` method that is called when the plugin
is loaded.

The three steps for creating a plugin are:

* create a new Ruby gem: `logging-<name>`
* include a plugin file: `lib/logging/plugins/<name>.rb`
* definie a plugin initializer: `Logging::Plugins::<Name>.initialize_<name>`

### Development

The Logging source code relies on the Mr Bones project for default rake tasks.
You will need to install the Mr Bones gem if you want to build or test the
logging gem. Conveniently there is a bootstrap script that you can run to setup
your development environment.

```
script/bootstrap
```

This will install the Mr Bones gem and the required Ruby gems for development.
After this is done you can rake `rake -T` to see the available rake tasks.

### License

The MIT License - see the [LICENSE](/LICENSE) file for the full text.


module Logging
  module Appenders

    # call-seq:
    #    Appenders[name]
    #
    # Returns the appender instance stored in the appender hash under the
    # key _name_, or +nil+ if no appender has been created using that name.
    #
    def []( name ) @appenders[name] end

    # call-seq:
    #    Appenders[name] = appender
    #
    # Stores the given _appender_ instance in the appender hash under the
    # key _name_.
    #
    def []=( name, value ) @appenders[name] = value end

    # call-seq:
    #    Appenders.remove( name )
    #
    # Removes the appender instance stored in the appender hash under the
    # key _name_.
    #
    def remove( name ) @appenders.delete(name) end

    # call-seq:
    #    each {|appender| block}
    #
    # Yield each appender to the _block_.
    #
    def each( &block )
      @appenders.values.each(&block)
      return nil
    end

    # :stopdoc:
    def reset
      @appenders.values.each {|appender|
        next if appender.nil?
        appender.close
      }
      @appenders.clear
      return nil
    end
    # :startdoc:

    extend self
    @appenders = Hash.new
  end  # Appenders

  require libpath('logging/appenders/buffering')
  require libpath('logging/appenders/io')
  require libpath('logging/appenders/console')
  require libpath('logging/appenders/file')
  require libpath('logging/appenders/rolling_file')
  require libpath('logging/appenders/string_io')
  require libpath('logging/appenders/syslog')
end  # Logging


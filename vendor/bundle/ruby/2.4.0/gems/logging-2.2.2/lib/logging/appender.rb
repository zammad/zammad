
module Logging

# The +Appender+ class is provides methods for appending log events to a
# logging destination. The log events are formatted into strings using a
# Layout.
#
# All other Appenders inherit from this class which provides stub methods.
# Each subclass should provide a +write+ method that will write log
# messages to the logging destination.
#
# A private +sync+ method is provided for use by subclasses. It is used to
# synchronize writes to the logging destination, and can be used by
# subclasses to synchronize the closing or flushing of the logging
# destination.
#
class Appender

  attr_reader :name, :layout, :level, :filters

  # call-seq:
  #    Appender.new( name )
  #    Appender.new( name, :layout => layout )
  #
  # Creates a new appender using the given name. If no Layout is specified,
  # then a Basic layout will be used. Any logging header supplied by the
  # layout will be written to the logging destination when the Appender is
  # created.
  #
  # Options:
  #
  #    :layout   => the layout to use when formatting log events
  #    :level    => the level at which to log
  #    :encoding => encoding to use when writing messages (defaults to UTF-8)
  #    :filters  => filters to apply to events before processing
  #
  def initialize( name, opts = {} )
    ::Logging.init unless ::Logging.initialized?

    @name    = name.to_s
    @closed  = false
    @filters = []
    @mutex   = ReentrantMutex.new

    self.layout   = opts.fetch(:layout, ::Logging::Layouts::Basic.new)
    self.level    = opts.fetch(:level, nil)
    self.encoding = opts.fetch(:encoding, self.encoding)
    self.filters  = opts.fetch(:filters, nil)

    if opts.fetch(:header, true)
      header = @layout.header

      unless header.nil? || header.empty?
        begin
          write(header)
        rescue StandardError => err
          ::Logging.log_internal_error(err)
        end
      end
    end

    ::Logging::Appenders[@name] = self
  end

  # call-seq:
  #    append( event )
  #
  # Write the given _event_ to the logging destination. The log event will
  # be processed through the Layout associated with the Appender.
  #
  def append( event )
    if @closed
      raise RuntimeError,
            "appender '<#{self.class.name}: #{@name}>' is closed"
    end

    # only append if the event level is less than or equal to the configured
    # appender level and the filter does not disallow it
    if event = allow(event)
      begin
        write(event)
      rescue StandardError => err
        ::Logging.log_internal_error(err)
      end
    end

    self
  end

  # call-seq:
  #    appender << string
  #
  # Write the given _string_ to the logging destination "as is" -- no
  # layout formatting will be performed.
  #
  def <<( str )
    if @closed
      raise RuntimeError,
            "appender '<#{self.class.name}: #{@name}>' is closed"
    end

    unless off?
      begin
        write(str)
      rescue StandardError => err
        ::Logging.log_internal_error(err)
      end
    end
    self
  end

  # call-seq:
  #    level = :all
  #
  # Set the level for this appender; log events below this level will be
  # ignored by this appender. The level can be either a +String+, a
  # +Symbol+, or an +Integer+. An +ArgumentError+ is raised if this is not
  # the case.
  #
  # There are two special levels -- "all" and "off". The former will
  # enable recording of all log events. The latter will disable the
  # recording of all events.
  #
  # Example:
  #
  #    appender.level = :debug
  #    appender.level = "INFO"
  #    appender.level = 4
  #    appender.level = 'off'
  #    appender.level = :all
  #
  # These produce an +ArgumentError+
  #
  #    appender.level = Object
  #    appender.level = -1
  #    appender.level = 1_000_000_000_000
  #
  def level=( level )
    lvl = case level
          when String, Symbol; ::Logging::level_num(level)
          when Integer; level
          when nil; 0
          else
            raise ArgumentError,
                  "level must be a String, Symbol, or Integer"
          end
    if lvl.nil? or lvl < 0 or lvl > ::Logging::LEVELS.length
      raise ArgumentError, "unknown level was given '#{level}'"
    end

    @level = lvl
  end

  # call-seq
  #    appender.layout = Logging::Layouts::Basic.new
  #
  # Sets the layout to be used by this appender.
  #
  def layout=( layout )
    unless layout.kind_of? ::Logging::Layout
      raise TypeError,
            "#{layout.inspect} is not a kind of 'Logging::Layout'"
    end
    @layout = layout
  end

  # Sets the filter(s) to be used by this appender. This method will clear the
  # current filter set and add those passed to this setter method.
  #
  # Examples
  #    appender.filters = Logging::Filters::Level.new(:warn, :error)
  #
  def filters=( args )
    @filters.clear
    add_filters(*args)
  end

  # Sets the filter(s) to be used by this appender. The filters will be
  # applied in the order that they are added to the appender.
  #
  # Examples
  #    add_filters(Logging::Filters::Level.new(:warn, :error))
  #
  # Returns this appender instance.
  def add_filters( *args )
    args.flatten.each do |filter|
      next if filter.nil?
      unless filter.kind_of?(::Logging::Filter)
        raise TypeError, "#{filter.inspect} is not a kind of 'Logging::Filter'"
      end
      @filters << filter
    end
    self
  end

  # call-seq:
  #    close( footer = true )
  #
  # Close the appender and writes the layout footer to the logging
  # destination if the _footer_ flag is set to +true+. Log events will
  # no longer be written to the logging destination after the appender
  # is closed.
  #
  def close( footer = true )
    return self if @closed
    ::Logging::Appenders.remove(@name)
    @closed = true

    flush

    if footer
      footer = @layout.footer
      unless footer.nil? || footer.empty?
        begin
          write(footer)
        rescue StandardError => err
          ::Logging.log_internal_error(err)
        end
      end
    end
    self
  end

  # call-seq:
  #    closed?
  #
  # Returns +true+ if the appender has been closed; returns +false+
  # otherwise. When an appender is closed, no more log events can be
  # written to the logging destination.
  #
  def closed?
    @closed
  end

  # Reopen the connection to the underlying logging destination. If the
  # connection is currently closed then it will be opened. If the connection
  # is currently open then it will be closed and immediately opened.
  #
  def reopen
    @closed = false
    self
  end

  # call-seq:
  #    flush
  #
  # Call +flush+ to force an appender to write out any buffered log events.
  # Similar to IO#flush, so use in a similar fashion.
  #
  def flush
    self
  end

  # Save off the original `to_s` for use in tests
  alias_method :_to_s, :to_s

  # call-seq:
  #     to_s => string
  #
  # Returns a string representation of the appender.
  #
  def to_s
    "<%s name=\"%s\">" % [self.class.name.sub(%r/^Logging::/, ''), self.name]
  end

  # Returns the current Encoding for the appender or nil if an encoding has
  # not been set.
  #
  def encoding
    return @encoding if defined? @encoding
    @encoding = Object.const_defined?(:Encoding) ? Encoding.default_external : nil
  end

  # Set the appender encoding to the given value. The value can either be an
  # Encoding instance or a String or Symbol referring to a valid encoding.
  #
  # This method only applies to Ruby 1.9 or later. The encoding will always be
  # nil for older Rubies.
  #
  # value - The encoding as a String, Symbol, or Encoding instance.
  #
  # Raises ArgumentError if the value is not a valid encoding.
  def encoding=( value )
    if value.nil?
      @encoding = nil
    else
      @encoding = Object.const_defined?(:Encoding) ? Encoding.find(value.to_s) : nil
    end
  end

  # Check to see if the event should be processed by the appender. An event will
  # be rejected if the event level is lower than the configured level for the
  # appender. Or it will be rejected if one of the filters rejects the event.
  #
  # event - The LogEvent to check
  #
  # Returns the event if it is allowed; returns `nil` if it is not allowed.
  def allow( event )
    return nil if @level > event.level
    @filters.each do |filter|
      break unless event = filter.allow(event)
    end
    event
  end

  # Returns `true` if the appender has been turned off. This is useful for
  # appenders that write data to a remote location (such as syslog or email),
  # and that write encounters too many errors. The appender can turn itself off
  # to and log an error via the `Logging` logger.
  #
  # Set the appender's level to a valid value to turn it back on.
  def off?
    @level >= ::Logging::LEVELS.length
  end


private

  # call-seq:
  #    write( event )
  #
  # Writes the given _event_ to the logging destination. Subclasses should
  # provide an implementation of this method. The _event_ can be either a
  # LogEvent or a String. If a LogEvent, then it will be formatted using
  # the layout given to the appender when it was created.
  #
  def write( event )
    nil
  end

  # call-seq:
  #    sync { block }
  #
  # Obtains an exclusive lock, runs the block, and releases the lock when
  # the block completes. This method is re-entrant so that a single thread
  # can call +sync+ multiple times without hanging the thread.
  #
  def sync( &block )
    @mutex.synchronize(&block)
  end

end  # class Appender
end  # module Logging



module Logging::Appenders

  # Accessor / Factory for the StringIo appender.
  #
  def self.string_io( *args )
    return ::Logging::Appenders::StringIo if args.empty?
    ::Logging::Appenders::StringIo.new(*args)
  end

  # This class provides an Appender that can write to a StringIO instance.
  # This is very useful for testing log message output.
  #
  class StringIo < ::Logging::Appenders::IO

    # The StringIO instance the appender is writing to.
    attr_reader :sio

    # call-seq:
    #    StringIo.new( name, opts = {} )
    #
    # Creates a new StringIo appender that will append log messages to a
    # StringIO instance.
    #
    def initialize( name, opts = {} )
      @sio = StringIO.new
      @sio.extend IoToS
      @pos = 0
      super(name, @sio, opts)
    end

    # Reopen the underlying StringIO instance. If the instance is currently
    # closed then it will be opened. If the instance is currently open then it
    # will be closed and immediately opened.
    #
    def reopen
      @mutex.synchronize {
        if defined? @io and @io
          flush
          @io.close rescue nil
        end
        @io = @sio = StringIO.new
        @sio.extend IoToS
        @pos = 0
      }
      super
      self
    end

    # Clears the internal StringIO instance. All log messages are removed
    # from the buffer.
    #
    def clear
      @mutex.synchronize {
        @pos = 0
        @sio.seek 0
        @sio.truncate 0
      }
    end
    alias_method :reset, :clear

    %w[read readline readlines].each do|m|
      class_eval <<-CODE, __FILE__, __LINE__+1
        def #{m}( *args )
          sync {
            begin
              @sio.seek @pos
              rv = @sio.#{m}(*args)
              @pos = @sio.tell
              rv
            rescue EOFError
              nil
            end
          }
        end
      CODE
    end

    # :stopdoc:
    module IoToS
      def to_s
        seek 0
        str = read
        seek 0
        return str
      end
    end
    # :startdoc:

  end  # StringIo
end  # Logging::Appenders


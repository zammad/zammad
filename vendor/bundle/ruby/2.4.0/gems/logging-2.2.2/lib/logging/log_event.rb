
module Logging

  # This class defines a logging event.
  class LogEvent
    # :stopdoc:

    # Regular expression used to parse out caller information
    #
    # * $1 == filename
    # * $2 == line number
    # * $3 == method name (might be nil)
    CALLER_RGXP = %r/([-\.\/\(\)\w]+):(\d+)(?::in `([^']+)')?/o
    #CALLER_INDEX = 2
    CALLER_INDEX = ((defined? JRUBY_VERSION and JRUBY_VERSION > '1.6') or (defined? RUBY_ENGINE and RUBY_ENGINE[%r/^rbx/i])) ? 1 : 2
    # :startdoc:

    attr_accessor :logger, :level, :data, :time, :file, :line, :method

    # call-seq:
    #    LogEvent.new( logger, level, [data], caller_tracing )
    #
    # Creates a new log event with the given _logger_ name, numeric _level_,
    # array of _data_ from the user to be logged, and boolean _caller_tracing_ flag.
    # If the _caller_tracing_ flag is set to +true+ then Kernel::caller will be
    # invoked to get the execution trace of the logging method.
    #
    def initialize( logger, level, data, caller_tracing )
      self.logger = logger
      self.level  = level
      self.data   = data
      self.time   = Time.now.freeze

      if caller_tracing
        stack = Kernel.caller[CALLER_INDEX]
        return if stack.nil?

        match = CALLER_RGXP.match(stack)
        self.file   = match[1]
        self.line   = Integer(match[2])
        self.method = match[3] unless match[3].nil?

        if (bp = ::Logging.basepath) && !bp.empty? && file.index(bp) == 0
          self.file = file.slice(bp.length + 1, file.length - bp.length)
        end
      else
        self.file = self.line = self.method = ''
      end
    end
  end
end

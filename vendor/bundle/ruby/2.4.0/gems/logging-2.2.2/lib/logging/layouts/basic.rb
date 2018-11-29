
module Logging::Layouts

  # Accessor / Factory for the Basic layout.
  #
  def self.basic( *args )
    return ::Logging::Layouts::Basic if args.empty?
    ::Logging::Layouts::Basic.new(*args)
  end

  # The +Basic+ layout class provides methods for simple formatting of log
  # events. The resulting string follows the format below.
  #
  #     LEVEL  LoggerName : log message
  #
  # _LEVEL_ is the log level of the event. _LoggerName_ is the name of the
  # logger that generated the event. <em>log message</em> is the message
  # or object that was passed to the logger. If multiple message or objects
  # were passed to the logger then each will be printed on its own line with
  # the format show above.
  #
  class Basic < ::Logging::Layout

    # call-seq:
    #    format( event )
    #
    # Returns a string representation of the given logging _event_. See the
    # class documentation for details about the formatting used.
    #
    def format( event )
      obj = format_obj(event.data)
      sprintf("%*s  %s : %s\n", ::Logging::MAX_LEVEL_LENGTH,
              ::Logging::LNAMES[event.level], event.logger, obj)
    end

  end  # Basic
end  # Logging::Layouts


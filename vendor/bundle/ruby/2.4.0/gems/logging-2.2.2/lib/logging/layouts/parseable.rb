require 'socket'

module Logging::Layouts

  # Accessor for the Parseable layout.
  #
  def self.parseable
    ::Logging::Layouts::Parseable
  end

  # Factory for the Parseable layout using JSON formatting.
  #
  def self.json( *args )
    ::Logging::Layouts::Parseable.json(*args)
  end

  # Factory for the Parseable layout using YAML formatting.
  #
  def self.yaml( *args )
    ::Logging::Layouts::Parseable.yaml(*args)
  end

  # This layout will produce parseable log output in either JSON or YAML
  # format. This makes it much easier for machines to parse log files and
  # perform analysis on those logs.
  #
  # The information about the log event can be configured when the layout is
  # created. Any or all of the following labels can be set as the _items_ to
  # log:
  #
  #   'logger'     Used to output the name of the logger that generated the
  #                log event.
  #   'timestamp'  Used to output the timestamp of the log event.
  #   'level'      Used to output the level of the log event.
  #   'message'    Used to output the application supplied message
  #                associated with the log event.
  #   'file'       Used to output the file name where the logging request
  #                was issued.
  #   'line'       Used to output the line number where the logging request
  #                was issued.
  #   'method'     Used to output the method name where the logging request
  #                was issued.
  #   'hostname'   Used to output the hostname
  #   'pid'        Used to output the process ID of the currently running
  #                program.
  #   'millis'     Used to output the number of milliseconds elapsed from
  #                the construction of the Layout until creation of the log
  #                event.
  #   'thread_id'  Used to output the object ID of the thread that generated
  #                the log event.
  #   'thread'     Used to output the name of the thread that generated the
  #                log event. Name can be specified using Thread.current[:name]
  #                notation. Output empty string if name not specified. This
  #                option helps to create more human readable output for
  #                multithread application logs.
  #
  # These items are supplied to the layout as an array of strings. The items
  # 'file', 'line', and 'method' will only work if the Logger generating the
  # events is configured to generate tracing information. If this is not the
  # case these fields will always be empty.
  #
  # When configured to output log events in YAML format, each log message
  # will be formatted as a hash in it's own YAML document. The hash keys are
  # the name of the item, and the value is what you would expect it to be.
  # Therefore, for the default set of times log message would appear as
  # follows:
  #
  #   ---
  #   timestamp: 2009-04-17T16:15:42
  #   level: INFO
  #   logger: Foo::Bar
  #   message: this is a log message
  #   ---
  #   timestamp: 2009-04-17T16:15:43
  #   level: ERROR
  #   logger: Foo
  #   message: <RuntimeError> Oooops!!
  #
  # The output order of the fields is not guaranteed to be the same as the
  # order specified in the _items_ list. This is because Ruby hashes are not
  # ordered by default (unless you're running this in Ruby 1.9).
  #
  # When configured to output log events in JSON format, each log message
  # will be formatted as an object (in the JSON sense of the word) on it's
  # own line in the log output. Therefore, to parse the output you must read
  # it line by line and parse the individual objects. Taking the same
  # example above the JSON output would be:
  #
  #   {"timestamp":"2009-04-17T16:15:42","level":"INFO","logger":"Foo::Bar","message":"this is a log message"}
  #   {"timestamp":"2009-04-17T16:15:43","level":"ERROR","logger":"Foo","message":"<RuntimeError> Oooops!!"}
  #
  # The output order of the fields is guaranteed to be the same as the order
  # specified in the _items_ list.
  #
  class Parseable < ::Logging::Layout

    # :stopdoc:
    # Arguments to sprintf keyed to directive letters
    DIRECTIVE_TABLE = {
      'logger'    => 'event.logger'.freeze,
      'timestamp' => 'iso8601_format(event.time)'.freeze,
      'level'     => '::Logging::LNAMES[event.level]'.freeze,
      'message'   => 'format_obj(event.data)'.freeze,
      'file'      => 'event.file'.freeze,
      'line'      => 'event.line'.freeze,
      'method'    => 'event.method'.freeze,
      'hostname'  => "'#{Socket.gethostname}'".freeze,
      'pid'       => 'Process.pid'.freeze,
      'millis'    => 'Integer((event.time-@created_at)*1000)'.freeze,
      'thread_id' => 'Thread.current.object_id'.freeze,
      'thread'    => 'Thread.current[:name]'.freeze,
      'mdc'       => 'Logging::MappedDiagnosticContext.context'.freeze,
      'ndc'       => 'Logging::NestedDiagnosticContext.context'.freeze
    }

    # call-seq:
    #    Pattern.create_yaml_format_methods( layout )
    #
    # This method will create the +format+ method in the given Parseable
    # _layout_ based on the configured items for the layout instance.
    #
    def self.create_yaml_format_method( layout )
      code = "undef :format if method_defined? :format\n"
      code << "def format( event )\nstr = {\n"

      code << layout.items.map {|name|
        "'#{name}' => #{Parseable::DIRECTIVE_TABLE[name]}"
      }.join(",\n")
      code << "\n}.to_yaml\nreturn str\nend\n"

      (class << layout; self end).class_eval(code, __FILE__, __LINE__)
    end

    # call-seq:
    #    Pattern.create_json_format_methods( layout )
    #
    # This method will create the +format+ method in the given Parseable
    # _layout_ based on the configured items for the layout instance.
    #
    def self.create_json_format_method( layout )
      code = "undef :format if method_defined? :format\n"
      code << "def format( event )\nh = {\n"

      code << layout.items.map {|name|
        "'#{name}' => #{Parseable::DIRECTIVE_TABLE[name]}"
      }.join(",\n")
      code << "\n}\nMultiJson.encode(h) << \"\\n\"\nend\n"

      (class << layout; self end).class_eval(code, __FILE__, __LINE__)
    end
    # :startdoc:

    # call-seq:
    #    Parseable.json( opts )
    #
    # Create a new Parseable layout that outputs log events using JSON style
    # formatting. See the initializer documentation for available options.
    #
    def self.json( opts = {} )
      opts[:style] = 'json'
      new(opts)
    end

    # call-seq:
    #    Parseable.yaml( opts )
    #
    # Create a new Parseable layout that outputs log events using YAML style
    # formatting. See the initializer documentation for available options.
    #
    def self.yaml( opts = {} )
      opts[:style] = 'yaml'
      new(opts)
    end

    # call-seq:
    #    Parseable.new( opts )
    #
    # Creates a new Parseable layout using the following options:
    #
    #    :style      => :json or :yaml
    #    :items      => %w[timestamp level logger message]
    #    :utc_offset =>  "-06:00" or -21600 or "UTC"
    #
    def initialize( opts = {} )
      super
      @created_at = Time.now
      @style = opts.fetch(:style, 'json').to_s.intern
      self.items = opts.fetch(:items, %w[timestamp level logger message])
    end

    attr_reader :items

    # call-seq:
    #    layout.items = %w[timestamp level logger message]
    #
    # Set the log event items that will be formatted by this layout. These
    # items, and only these items, will appear in the log output.
    #
    def items=( ary )
      @items = Array(ary).map {|name| name.to_s.downcase}
      valid = DIRECTIVE_TABLE.keys
      @items.each do |name|
        raise ArgumentError, "unknown item - #{name.inspect}" unless valid.include? name
      end
      create_format_method
    end

    # Public: Take a given object and convert it into a format suitable for
    # inclusion as a log message. The conversion allows the object to be more
    # easily expressed in YAML or JSON form.
    #
    # If the object is an Exception, then this method will return a Hash
    # containing the exception class name, message, and backtrace (if any).
    #
    # obj - The Object to format
    #
    # Returns the formatted Object.
    #
    def format_obj( obj )
      case obj
      when Exception
        hash = {
          :class   => obj.class.name,
          :message => obj.message
        }
        hash[:backtrace] = obj.backtrace if backtrace? && obj.backtrace

        cause = format_cause(obj)
        hash[:cause] = cause unless cause.empty?
        hash
      when Time
        iso8601_format(obj)
      else
        obj
      end
    end

    # Internal: Format any nested exceptions found in the given exception `e`
    # while respecting the maximum `cause_depth`.
    #
    # e - Exception to format
    #
    # Returns the cause formatted as a Hash
    def format_cause(e)
      rv = curr = {}
      prev = nil

      cause_depth.times do
        break unless e.respond_to?(:cause) && e.cause

        cause = e.cause
        curr[:class]     = cause.class.name
        curr[:message]   = cause.message
        curr[:backtrace] = format_cause_backtrace(e, cause) if backtrace? && cause.backtrace

        prev[:cause] = curr unless prev.nil?
        prev, curr = curr, {}

        e = cause
      end

      if e.respond_to?(:cause) && e.cause
        prev[:cause] = {message: "Further #cause backtraces were omitted"}
      end

      rv
    end

  private

    # Call the appropriate class level create format method based on the
    # style of this parseable layout.
    #
    def create_format_method
      case @style
      when :json; Parseable.create_json_format_method(self)
      when :yaml; Parseable.create_yaml_format_method(self)
      else raise ArgumentError, "unknown format style '#@style'" end
    end

    # Convert the given `time` into an ISO8601 formatted time string.
    #
    def iso8601_format( time )
      value = apply_utc_offset(time)

      str = value.strftime('%Y-%m-%dT%H:%M:%S')
      str << ('.%06d' % value.usec)

      offset = value.gmt_offset.abs
      return str << 'Z' if offset == 0

      offset = sprintf('%02d:%02d', offset / 3600, offset % 3600 / 60)
      return str << (value.gmt_offset < 0 ? '-' : '+') << offset
    end

  end
end

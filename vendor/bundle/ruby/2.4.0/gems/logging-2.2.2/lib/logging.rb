require File.expand_path('../logging/utils', __FILE__)

require 'yaml'
require 'stringio'
require 'fileutils'
require 'little-plugger'
require 'multi_json'

begin
  require 'syslog'
  HAVE_SYSLOG = true
rescue LoadError
  HAVE_SYSLOG = false
end

#
#
module Logging
  extend LittlePlugger

  # :stopdoc:
  LIBPATH = ::File.expand_path('..', __FILE__) + ::File::SEPARATOR
  PATH = ::File.expand_path('../..', __FILE__) + ::File::SEPARATOR
  LEVELS = {}
  LNAMES = []
  DEFAULT_CAUSE_DEPTH = 8

  module Plugins; end
  # :startdoc:

  class << self

    # call-seq:
    #    Logging.logger( device, age = 7, size = 1048576 )
    #    Logging.logger( device, age = 'weekly' )
    #
    # This convenience method returns a Logger instance configured to behave
    # similarly to a core Ruby Logger instance.
    #
    # The _device_ is the logging destination. This can be a filename
    # (String) or an IO object (STDERR, STDOUT, an open File, etc.). The
    # _age_ is the number of old log files to keep or the frequency of
    # rotation (+daily+, +weekly+, or +monthly+). The _size_ is the maximum
    # logfile size and is only used when _age_ is a number.
    #
    # Using the same _device_ twice will result in the same Logger instance
    # being returned. For example, if a Logger is created using STDOUT then
    # the same Logger instance will be returned the next time STDOUT is
    # used. A new Logger instance can be obtained by closing the previous
    # logger instance.
    #
    #    log1 = Logging.logger(STDOUT)
    #    log2 = Logging.logger(STDOUT)
    #    log1.object_id == log2.object_id  #=> true
    #
    #    log1.close
    #    log2 = Logging.logger(STDOUT)
    #    log1.object_id == log2.object_id  #=> false
    #
    # The format of the log messages can be changed using a few optional
    # parameters. The <tt>:pattern</tt> can be used to change the log
    # message format. The <tt>:date_pattern</tt> can be used to change how
    # timestamps are formatted.
    #
    #    log = Logging.logger(STDOUT,
    #              :pattern => "[%d] %-5l : %m\n",
    #              :date_pattern => "%Y-%m-%d %H:%M:%S.%s")
    #
    # See the documentation for the Logging::Layouts::Pattern class for a
    # full description of the :pattern and :date_pattern formatting strings.
    #
    def logger( *args )
      return ::Logging::Logger if args.empty?

      opts = args.pop if args.last.instance_of?(Hash)
      opts ||= Hash.new

      dev = args.shift
      keep = age = args.shift
      size = args.shift

      name = case dev
             when String; dev
             when File; dev.path
             else dev.object_id.to_s end

      repo = ::Logging::Repository.instance
      return repo[name] if repo.has_logger? name

      l_opts = {
        :pattern => "%.1l, [%d #%p] %#{::Logging::MAX_LEVEL_LENGTH}l : %m\n",
        :date_pattern => '%Y-%m-%dT%H:%M:%S.%s'
      }
      [:pattern, :date_pattern, :date_method].each do |o|
        l_opts[o] = opts.delete(o) if opts.has_key? o
      end
      layout = ::Logging::Layouts::Pattern.new(l_opts)

      a_opts = Hash.new
      a_opts[:size] = size if size.is_a?(Integer)
      a_opts[:age]  = age  if age.instance_of?(String)
      a_opts[:keep] = keep if keep.is_a?(Integer)
      a_opts[:filename] = dev if dev.instance_of?(String)
      a_opts[:layout] = layout
      a_opts.merge! opts

      appender =
          case dev
          when String
            ::Logging::Appenders::RollingFile.new(name, a_opts)
          else
            ::Logging::Appenders::IO.new(name, dev, a_opts)
          end

      logger = ::Logging::Logger.new(name)
      logger.add_appenders appender
      logger.additive = false

      class << logger
        def close
          @appenders.each {|a| a.close}
          h = ::Logging::Repository.instance.instance_variable_get :@h
          h.delete(@name)
          class << self; undef :close; end
        end
      end

      logger
    end

    # Access to the layouts.
    #
    def layouts
      ::Logging::Layouts
    end

    # Access to the appenders.
    #
    def appenders
      ::Logging::Appenders
    end

    # Returns the color scheme identified by the given _name_. If there is no
    # color scheme +nil+ is returned.
    #
    # If color scheme options are supplied then a new color scheme is created.
    # Any existing color scheme with the given _name_ will be replaced by the
    # new color scheme.
    #
    def color_scheme( name, opts = {} )
      if opts.empty?
        ::Logging::ColorScheme[name]
      else
        ::Logging::ColorScheme.new(name, opts)
      end
    end

    # Reopen all appenders. This method should be called immediately after a
    # fork to ensure no conflict with file descriptors and calls to fcntl or
    # flock.
    #
    def reopen
      log_internal {'re-opening all appenders'}
      ::Logging::Appenders.each {|appender| appender.reopen}
      self
    end

    # call-seq:
    #    include Logging.globally
    #    include Logging.globally( :logger )
    #
    # Add a "logger" method to the including context. If included from
    # Object or Kernel, the logger method will be available to all objects.
    #
    # Optionally, a method name can be given and that will be used to
    # provided access to the logger:
    #
    #    include Logging.globally( :log )
    #    log.info "Just using a shorter method name"
    #
    # If you prefer to use the shorter "log" to access the logger.
    #
    # ==== Example
    #
    #   include Logging.globally
    #
    #   class Foo
    #     logger.debug "Loading the Foo class"
    #     def initialize
    #       logger.info "Creating some new foo"
    #     end
    #   end
    #
    #   logger.fatal "End of example"
    #
    def globally( name = :logger )
      Module.new {
        eval "def #{name}() @_logging_logger ||= ::Logging::Logger[self] end"
      }
    end

    # call-seq:
    #    Logging.init( levels )
    #
    # Defines the levels available to the loggers. The _levels_ is an array
    # of strings and symbols. Each element in the array is downcased and
    # converted to a symbol; these symbols are used to create the logging
    # methods in the loggers.
    #
    # The first element in the array is the lowest logging level. Setting the
    # logging level to this value will enable all log messages. The last
    # element in the array is the highest logging level. Setting the logging
    # level to this value will disable all log messages except this highest
    # level.
    #
    # This method should be invoked only once to configure the logging
    # levels. It is automatically invoked with the default logging levels
    # when the first logger is created.
    #
    # The levels "all" and "off" are reserved and will be ignored if passed
    # to this method.
    #
    # Example:
    #
    #    Logging.init :debug, :info, :warn, :error, :fatal
    #    log = Logging::Logger['my logger']
    #    log.level = :warn
    #    log.warn 'Danger! Danger! Will Robinson'
    #    log.info 'Just FYI'                        # => not logged
    #
    # or
    #
    #    Logging.init %w(DEBUG INFO NOTICE WARNING ERR CRIT ALERT EMERG)
    #    log = Logging::Logger['syslog']
    #    log.level = :notice
    #    log.warning 'This is your first warning'
    #    log.info 'Just FYI'                        # => not logged
    #
    def init( *args )
      args = %w(debug info warn error fatal) if args.empty?

      args.flatten!
      levels = LEVELS.clear
      names = LNAMES.clear

      id = 0
      args.each do |lvl|
        lvl = levelify lvl
        unless levels.has_key?(lvl) or lvl == 'all' or lvl == 'off'
          levels[lvl] = id
          names[id] = lvl.upcase
          id += 1
        end
      end

      longest = names.inject {|x,y| (x.length > y.length) ? x : y}
      longest = 'off' if longest.length < 3
      module_eval "MAX_LEVEL_LENGTH = #{longest.length}", __FILE__, __LINE__

      self.cause_depth = nil unless defined? @cause_depth

      initialize_plugins
      levels.keys
    end

    # call-seq:
    #    Logging.format_as( obj_format )
    #
    # Defines the default _obj_format_ method to use when converting objects
    # into string representations for logging. _obj_format_ can be one of
    # <tt>:string</tt>, <tt>:inspect</tt>, or <tt>:yaml</tt>. These
    # formatting commands map to the following object methods
    #
    # * :string  => to_s
    # * :inspect => inspect
    # * :yaml    => to_yaml
    # * :json    => MultiJson.encode(obj)
    #
    # An +ArgumentError+ is raised if anything other than +:string+,
    # +:inspect+, +:yaml+ is passed to this method.
    #
    def format_as( f )
      f = f.intern if f.instance_of? String

      unless [:string, :inspect, :yaml, :json].include? f
        raise ArgumentError, "unknown object format '#{f}'"
      end

      module_eval "OBJ_FORMAT = :#{f}", __FILE__, __LINE__
      self
    end

    # call-seq:
    #    Logging.backtrace             #=> true or false
    #    Logging.backtrace( value )    #=> true or false
    #
    # Without any arguments, returns the global exception backtrace logging
    # value. When set to +true+ backtraces will be written to the logs; when
    # set to +false+ backtraces will be suppressed.
    #
    # When an argument is given the global exception backtrace setting will
    # be changed. Value values are <tt>"on"</tt>, <tt>:on<tt> and +true+ to
    # turn on backtraces and <tt>"off"</tt>, <tt>:off</tt> and +false+ to
    # turn off backtraces.
    #
    def backtrace( b = nil )
      @backtrace = true unless defined? @backtrace
      return @backtrace if b.nil?

      @backtrace = case b
          when :on, 'on', true;    true
          when :off, 'off', false; false
          else
            raise ArgumentError, "backtrace must be true or false"
          end
    end

    # Set the default UTC offset used when formatting time values sent to the
    # appenders. If left unset, the default local time zone will be used for
    # time values. This method accepts the `utc_offset` format supported by the
    # `Time#localtime` method in Ruby.
    #
    # Passing "UTC" or `0` as the UTC offset will cause all times to be reported
    # in the UTC timezone.
    #
    #   Logging.utc_offset = "-07:00"  # Mountain Standard Time in North America
    #   Logging.utc_offset = "+01:00"  # Central European Time
    #   Logging.utc_offset = "UTC"     # UTC
    #   Logging.utc_offset = 0         # UTC
    #
    def utc_offset=( value )
      @utc_offset = case value
        when nil;             nil
        when "UTC", "GMT", 0; 0
        else
          Time.now.localtime(value)
          value
        end
    end

    attr_reader :utc_offset

    # Set the default Exception#cause depth used when formatting Exceptions.
    # This sets the maximum number of nested errors that will be formatted by
    # the layouts before giving up. This is used to avoid extremely large
    # outputs.
    #
    #   Logging.cause_depth = nil    # set to the DEFAULT_CAUSE_DEPTH
    #   Logging.cause_depth = 0      # do not show any exception causes
    #   Logging.cause_depth = 1024   # show up to 1024 causes
    #   Logging.cause_depth = -1     # results in the DEFAULT_CAUSE_DEPTH
    #
    def cause_depth=( value )
      if value.nil?
        @cause_depth = DEFAULT_CAUSE_DEPTH
      else
        value = Integer(value)
        @cause_depth = value < 0 ? DEFAULT_CAUSE_DEPTH : value
      end
    end

    attr_reader :cause_depth

    # Used to define a `basepath` that will be removed from filenames when
    # reporting tracing information for log events. Normally you would set this
    # to the root of your project:
    #
    #   Logging.basepath = "/home/user/nifty_project"
    #
    # Or if you are in a Rails environment:
    #
    #   Logging.basepath = Rails.root.to_s
    #
    # The basepath is expanded to a full path with trailing slashes removed.
    # This setting will be cleared by a call to `Logging.reset`.
    def basepath=( path )
      if path.nil? || path.to_s.empty?
        @basepath = nil
      else
        @basepath = File.expand_path(path)
      end
    end

    attr_reader :basepath

    # Returns the library path for the module. If any arguments are given,
    # they will be joined to the end of the library path using
    # <tt>File.join</tt>.
    #
    def libpath( *args, &block )
      rv = args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
      if block
        begin
          $LOAD_PATH.unshift LIBPATH
          rv = block.call
        ensure
          $LOAD_PATH.shift
        end
      end
      return rv
    end

    # Returns the lpath for the module. If any arguments are given,
    # they will be joined to the end of the path using
    # <tt>File.join</tt>.
    #
    def path( *args, &block )
      rv = args.empty? ? PATH : ::File.join(PATH, args.flatten)
      if block
        begin
          $LOAD_PATH.unshift PATH
          rv = block.call
        ensure
          $LOAD_PATH.shift
        end
      end
      return rv
    end

    # call-seq:
    #    show_configuration( io = STDOUT, logger = 'root' )
    #
    # This method is used to show the configuration of the logging
    # framework. The information is written to the given _io_ stream
    # (defaulting to stdout). Normally the configuration is dumped starting
    # with the root logger, but any logger name can be given.
    #
    # Each line contains information for a single logger and it's appenders.
    # A child logger is indented two spaces from it's parent logger. Each
    # line contains the logger name, level, additivity, and trace settings.
    # Here is a brief example:
    #
    #    root  ...........................   *info      -T
    #      LoggerA  ......................    info  +A  -T
    #        LoggerA::LoggerB  ...........    info  +A  -T
    #        LoggerA::LoggerC  ...........  *debug  +A  -T
    #      LoggerD  ......................   *warn  -A  +T
    #
    # The lines can be deciphered as follows:
    #
    #    1) name       - the name of the logger
    #
    #    2) level      - the logger level; if it is preceded by an
    #                    asterisk then the level was explicitly set for that
    #                    logger (as opposed to being inherited from the parent
    #                    logger)
    #
    #    3) additivity - a "+A" shows the logger is additive, and log events
    #                    will be passed up to the parent logger; "-A" shows
    #                    that the logger will *not* pass log events up to the
    #                    parent logger
    #
    #    4) tracing    - a "+T" shows that the logger will include caller
    #                    tracing information in generated log events (this
    #                    includes filename and line number of the log
    #                    message); "-T" shows that the logger does not include
    #                    caller tracing information in the log events
    #
    # If a logger has appenders then they are listed, one per line,
    # immediately below the logger. Appender lines are pre-pended with a
    # single dash:
    #
    #    root  ...........................   *info      -T
    #    - <Appenders::Stdout:0x8b02a4 name="stdout">
    #      LoggerA  ......................    info  +A  -T
    #        LoggerA::LoggerB  ...........    info  +A  -T
    #        LoggerA::LoggerC  ...........  *debug  +A  -T
    #      LoggerD  ......................   *warn  -A  +T
    #      - <Appenders::Stderr:0x8b04ca name="stderr">
    #
    # We can see in this configuration dump that all the loggers will append
    # to stdout via the Stdout appender configured in the root logger. All
    # the loggers are additive, and so their generated log events will be
    # passed up to the root logger.
    #
    # The exception in this configuration is LoggerD. Its additivity is set
    # to false. It uses its own appender to send messages to stderr.
    #
    def show_configuration( io = STDOUT, logger = 'root', indent = 0 )
      logger = ::Logging::Logger[logger] unless logger.is_a?(::Logging::Logger)

      io << logger._dump_configuration(indent)

      indent += 2
      children = ::Logging::Repository.instance.children(logger.name)
      children.sort {|a,b| a.name <=> b.name}.each do |child|
        ::Logging.show_configuration(io, child, indent)
      end

      io
    end

    # :stopdoc:
    # Convert the given level into a canonical form - a lowercase string.
    def levelify( level )
      case level
      when String; level.downcase
      when Symbol; level.to_s.downcase
      else raise ArgumentError, "levels must be a String or Symbol" end
    end

    # Convert the given level into a level number.
    def level_num( level )
      l = levelify(level) rescue level
      case l
      when 'all'; 0
      when 'off'; LEVELS.length
      else begin; Integer(l); rescue ArgumentError; LEVELS[l] end end
    end

    # Internal logging method for use by the framework.
    def log_internal( level = 1, &block )
      ::Logging::Logger[::Logging].__send__(levelify(LNAMES[level]), &block)
    end

    # Internal logging method for handling exceptions. If the
    # `Thread#abort_on_exception` flag is set then the
    # exception will be raised again.
    def log_internal_error( err )
      log_internal(-2) { err }
      raise err if Thread.abort_on_exception
    end

    # Close all appenders
    def shutdown( *args )
      return unless initialized?
      log_internal {'shutdown called - closing all appenders'}
      ::Logging::Appenders.each {|appender| appender.close}
      nil
    end

    # Reset the Logging framework to it's uninitialized state
    def reset
      ::Logging::Repository.reset
      ::Logging::Appenders.reset
      ::Logging::ColorScheme.reset
      ::Logging.clear_diagnostic_contexts(true)
      LEVELS.clear
      LNAMES.clear
      remove_instance_variable :@backtrace if defined? @backtrace
      remove_instance_variable :@basepath  if defined? @basepath
      remove_const :MAX_LEVEL_LENGTH if const_defined? :MAX_LEVEL_LENGTH
      remove_const :OBJ_FORMAT if const_defined? :OBJ_FORMAT
      self.utc_offset  = nil
      self.cause_depth = nil
      self
    end

    # Return +true+ if the Logging framework is initialized.
    def initialized?
      const_defined? :MAX_LEVEL_LENGTH
    end
    # :startdoc:
  end

  require libpath('logging/version')
  require libpath('logging/appender')
  require libpath('logging/layout')
  require libpath('logging/filter')
  require libpath('logging/log_event')
  require libpath('logging/logger')
  require libpath('logging/repository')
  require libpath('logging/root_logger')
  require libpath('logging/color_scheme')
  require libpath('logging/appenders')
  require libpath('logging/layouts')
  require libpath('logging/filters')
  require libpath('logging/proxy')
  require libpath('logging/diagnostic_context')

  require libpath('logging/rails_compat')
end  # module Logging


# This finalizer will close all the appenders that exist in the system.
# This is needed for closing IO streams and connections to the syslog server
# or e-mail servers, etc.
#
# You can prevent the finalizer from running by calling `exit!` from your
# application. This is required when daemonizing.
#
ObjectSpace.define_finalizer self, Logging.method(:shutdown)

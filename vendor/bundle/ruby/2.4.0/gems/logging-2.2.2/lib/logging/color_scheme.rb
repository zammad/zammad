# color_scheme.rb
#
# Created by Jeremy Hinegardner on 2007-01-24
# Copyright 2007.  All rights reserved
#
# This file is licensed under the terms of the MIT License.
# See the README for licensing details.
#

module Logging

  # ColorScheme objects encapsulate a named set of colors to be used in the
  # colors() method call. For example, by applying a ColorScheme that
  # has a <tt>:warning</tt> color then the following could be used:
  #
  #   scheme.color("This is a warning", :warning)
  #
  # ColorScheme objects are used by the Pattern layout code to colorize log
  # messages. Each color scheme is given a unique name which is used by the
  # Pattern layout to lookup the appropriate color scheme to use. Please
  # refer to the Pattern layout documentation for more details - specifically
  # the initializer documentation.
  #
  # The color scheme can be applied to the Pattern layout in several ways.
  # Each token in the log pattern can be colorized with the log level (debug,
  # info, warn, etc) receiving unique colors based on the level itself.
  # Another option is to colorize the entire log message based on the log
  # level; in this mode tokens do not get their own colors. Please see the
  # ColorScheme initializer for the list of colorization options.
  #
  class ColorScheme

    class << self
      # Retrieve a color scheme by name.
      #
      def []( name )
        @color_schemes[name.to_s]
      end

      # Store a color scheme by name.
      #
      def []=( name, value )
        raise ArgumentError, "Silly! That's not a ColorSchmeme!" unless value.is_a?(ColorScheme)
        @color_schemes[name.to_s] = value
      end

      # Clear all color schemes and setup a default color scheme.
      #
      def reset
        @color_schemes ||= {}
        @color_schemes.clear

        new(:default, :levels => {
          :info  => :green,
          :warn  => :yellow,
          :error => :red,
          :fatal => [:white, :on_red]
        })
      end
    end

    # Create a ColorScheme instance that can be accessed using the given
    # _name_. If a color scheme already exists with the given _name_ it will
    # be replaced by the new color scheme.
    #
    # The color names are passed as options to the method with each name
    # mapping to one or more color codes. For example:
    #
    #    ColorScheme.new('example', :logger => [:white, :on_green], :message => :magenta)
    #
    # The color codes are the lowercase names of the constants defined at the
    # end of this file. Multiple color codes can be aliased by grouping them
    # in an array as shown in the example above.
    #
    # Since color schemes are primarily intended to be used with the Pattern
    # layout, there are a few special options of note. First the log levels
    # are enumerated in their own hash:
    #
    #    :levels => {
    #      :debug => :blue,
    #      :info  => :cyan,
    #      :warn  => :yellow,
    #      :error => :red,
    #      :fatal => [:white, :on_red]
    #    }
    #
    # The log level token will be colorized differently based on the value of
    # the log level itself. Similarly the entire log message can be colorized
    # based on the value of the log level. A different option should be given
    # for this behavior:
    #
    #    :lines => {
    #      :debug => :blue,
    #      :info  => :cyan,
    #      :warn  => :yellow,
    #      :error => :red,
    #      :fatal => [:white, :on_red]
    #    }
    #
    # The :levels and :lines options cannot be used together; only one or the
    # other should be given.
    #
    # The remaining tokens defined in the Pattern layout can be colorized
    # using the following aliases. Their meaning in the Pattern layout are
    # repeated here for sake of clarity.
    #
    #    :logger       [%c] name of the logger that generate the log event
    #    :date         [%d] datestamp
    #    :message      [%m] the user supplied log message
    #    :pid          [%p] PID of the current process
    #    :time         [%r] the time in milliseconds since the program started
    #    :thread       [%T] the name of the thread Thread.current[:name]
    #    :thread_id    [%t] object_id of the thread
    #    :file         [%F] filename where the logging request was issued
    #    :line         [%L] line number where the logging request was issued
    #    :method       [%M] method name where the logging request was issued
    #
    # Please refer to the "examples/colorization.rb" file for a working
    # example of log colorization.
    #
    def initialize( name, opts = {} )
      @scheme = Hash.new

      @lines = opts.key? :lines
      @levels = opts.key? :levels
      raise ArgumentError, "Found both :lines and :levels - only one can be used." if lines? and levels?

      lines = opts.delete :lines
      levels = opts.delete :levels

      load_from_hash(opts)
      load_from_hash(lines) if lines?
      load_from_hash(levels) if levels?

      ::Logging::ColorScheme[name] = self
    end

    # Load multiple colors from key/value pairs.
    #
    def load_from_hash( h )
      h.each_pair do |color_tag, constants|
        self[color_tag] = constants
      end
    end

    # Returns +true+ if the :lines option was passed to the constructor.
    #
    def lines?
      @lines
    end

    # Returns +true+ if the :levels option was passed to the constructor.
    #
    def levels?
      @levels
    end

    # Does this color scheme include the given tag name?
    #
    def include?( color_tag )
      @scheme.key?(to_key(color_tag))
    end

    # Allow the scheme to be accessed like a Hash.
    #
    def []( color_tag )
      @scheme[to_key(color_tag)]
    end

    # Allow the scheme to be set like a Hash.
    #
    def []=( color_tag, constants )
      @scheme[to_key(color_tag)] = constants.respond_to?(:map) ?
          constants.map { |c| to_constant(c) }.join : to_constant(constants)
    end

    # This method provides easy access to ANSI color sequences, without the user
    # needing to remember to CLEAR at the end of each sequence.  Just pass the
    # _string_ to color, followed by a list of _colors_ you would like it to be
    # affected by.  The _colors_ can be ColorScheme class constants, or symbols
    # (:blue for BLUE, for example).  A CLEAR will automatically be embedded to
    # the end of the returned String.
    #
    def color( string, *colors )
      colors.map! { |color|
        color_tag = to_key(color)
        @scheme.key?(color_tag) ? @scheme[color_tag] : to_constant(color)
      }

      colors.compact!
      return string if colors.empty?

      "#{colors.join}#{string}#{CLEAR}"
    end

  private

    # Return a normalized representation of a color name.
    #
    def to_key( t )
      t.to_s.downcase
    end

    # Return a normalized representation of a color setting.
    #
    def to_constant( v )
      v = v.to_s.upcase
      ColorScheme.const_get(v) if (ColorScheme.const_defined?(v, false) rescue ColorScheme.const_defined?(v))
    end

    # Embed in a String to clear all previous ANSI sequences.  This *MUST* be
    # done before the program exits!
    CLEAR      = "\e[0m".freeze
    RESET      = CLEAR              # An alias for CLEAR.
    ERASE_LINE = "\e[K".freeze      # Erase the current line of terminal output.
    ERASE_CHAR = "\e[P".freeze      # Erase the character under the cursor.
    BOLD       = "\e[1m".freeze     # The start of an ANSI bold sequence.
    DARK       = "\e[2m".freeze     # The start of an ANSI dark sequence.  (Terminal support uncommon.)
    UNDERLINE  = "\e[4m".freeze     # The start of an ANSI underline sequence.
    UNDERSCORE = UNDERLINE          # An alias for UNDERLINE.
    BLINK      = "\e[5m".freeze     # The start of an ANSI blink sequence.  (Terminal support uncommon.)
    REVERSE    = "\e[7m".freeze     # The start of an ANSI reverse sequence.
    CONCEALED  = "\e[8m".freeze     # The start of an ANSI concealed sequence.  (Terminal support uncommon.)

    BLACK      = "\e[30m".freeze    # Set the terminal's foreground ANSI color to black.
    RED        = "\e[31m".freeze    # Set the terminal's foreground ANSI color to red.
    GREEN      = "\e[32m".freeze    # Set the terminal's foreground ANSI color to green.
    YELLOW     = "\e[33m".freeze    # Set the terminal's foreground ANSI color to yellow.
    BLUE       = "\e[34m".freeze    # Set the terminal's foreground ANSI color to blue.
    MAGENTA    = "\e[35m".freeze    # Set the terminal's foreground ANSI color to magenta.
    CYAN       = "\e[36m".freeze    # Set the terminal's foreground ANSI color to cyan.
    WHITE      = "\e[37m".freeze    # Set the terminal's foreground ANSI color to white.

    ON_BLACK   = "\e[40m".freeze    # Set the terminal's background ANSI color to black.
    ON_RED     = "\e[41m".freeze    # Set the terminal's background ANSI color to red.
    ON_GREEN   = "\e[42m".freeze    # Set the terminal's background ANSI color to green.
    ON_YELLOW  = "\e[43m".freeze    # Set the terminal's background ANSI color to yellow.
    ON_BLUE    = "\e[44m".freeze    # Set the terminal's background ANSI color to blue.
    ON_MAGENTA = "\e[45m".freeze    # Set the terminal's background ANSI color to magenta.
    ON_CYAN    = "\e[46m".freeze    # Set the terminal's background ANSI color to cyan.
    ON_WHITE   = "\e[47m".freeze    # Set the terminal's background ANSI color to white.

    BRIGHT_RED        = "\e[1;31m".freeze    # Set the terminal's foreground ANSI color to bright red.
    BRIGHT_GREEN      = "\e[1;32m".freeze    # Set the terminal's foreground ANSI color to bright green.
    BRIGHT_YELLOW     = "\e[1;33m".freeze    # Set the terminal's foreground ANSI color to bright yellow.
    BRIGHT_BLUE       = "\e[1;34m".freeze    # Set the terminal's foreground ANSI color to bright blue.
    BRIGHT_MAGENTA    = "\e[1;35m".freeze    # Set the terminal's foreground ANSI color to bright magenta.
    BRIGHT_CYAN       = "\e[1;36m".freeze    # Set the terminal's foreground ANSI color to bright cyan.
    BRIGHT_WHITE      = "\e[1;37m".freeze    # Set the terminal's foreground ANSI color to bright white.

    ON_BRIGHT_RED     = "\e[1;41m".freeze    # Set the terminal's background ANSI color to bright red.
    ON_BRIGHT_GREEN   = "\e[1;42m".freeze    # Set the terminal's background ANSI color to bright green.
    ON_BRIGHT_YELLOW  = "\e[1;43m".freeze    # Set the terminal's background ANSI color to bright yellow.
    ON_BRIGHT_BLUE    = "\e[1;44m".freeze    # Set the terminal's background ANSI color to bright blue.
    ON_BRIGHT_MAGENTA = "\e[1;45m".freeze    # Set the terminal's background ANSI color to bright magenta.
    ON_BRIGHT_CYAN    = "\e[1;46m".freeze    # Set the terminal's background ANSI color to bright cyan.
    ON_BRIGHT_WHITE   = "\e[1;47m".freeze    # Set the terminal's background ANSI color to bright white.

  end  # ColorScheme

  # setup the default color scheme
  ColorScheme.reset

end  # Logging


module Diffy
  class Diff
    ORIGINAL_DEFAULT_OPTIONS = {
      :diff => '-U 10000',
      :source => 'strings',
      :include_diff_info => false,
      :include_plus_and_minus_in_html => false,
      :context => nil,
      :allow_empty_diff => true,
    }

    class << self
      attr_writer :default_format
      def default_format
        @default_format ||= :text
      end

      # default options passed to new Diff objects
      attr_writer :default_options
      def default_options
        @default_options ||= ORIGINAL_DEFAULT_OPTIONS.dup
      end

    end
    include Enumerable
    attr_reader :string1, :string2, :options

    # supported options
    # +:diff+::    A cli options string passed to diff
    # +:source+::  Either _strings_ or _files_.  Determines whether string1
    #              and string2 should be interpreted as strings or file paths.
    # +:include_diff_info+::    Include diff header info
    # +:include_plus_and_minus_in_html+::    Show the +, -, ' ' at the
    #                                        beginning of lines in html output.
    def initialize(string1, string2, options = {})
      @options = self.class.default_options.merge(options)
      if ! ['strings', 'files'].include?(@options[:source])
        raise ArgumentError, "Invalid :source option #{@options[:source].inspect}. Supported options are 'strings' and 'files'."
      end
      @string1, @string2 = string1, string2
    end

    def diff
      @diff ||= begin
        paths = case options[:source]
          when 'strings'
            [tempfile(string1), tempfile(string2)]
          when 'files'
            [string1, string2]
          end

        if WINDOWS
          # don't use open3 on windows
          cmd = sprintf '"%s" %s %s', diff_bin, diff_options.join(' '), paths.map { |s| %("#{s}") }.join(' ')
          diff = `#{cmd}`
        else
          diff = Open3.popen3(diff_bin, *(diff_options + paths)) { |i, o, e| o.read }
        end
        diff.force_encoding('ASCII-8BIT') if diff.respond_to?(:valid_encoding?) && !diff.valid_encoding?
        if diff =~ /\A\s*\Z/ && !options[:allow_empty_diff]
          diff = case options[:source]
          when 'strings' then string1
          when 'files' then File.read(string1)
          end.gsub(/^/, " ")
        end
        diff
      end
    ensure
      # unlink the tempfiles explicitly now that the diff is generated
      if defined? @tempfiles # to avoid Ruby warnings about undefined ins var.
        Array(@tempfiles).each do |t|
          begin
            # check that the path is not nil and file still exists.
            # REE seems to be very agressive with when it magically removes
            # tempfiles
            t.unlink if t.path && File.exist?(t.path)
          rescue => e
            warn "#{e.class}: #{e}"
            warn e.backtrace.join("\n")
          end
        end
      end
    end

    def each
      lines = case @options[:include_diff_info]
      when false then diff.split("\n").reject{|x| x =~ /^(---|\+\+\+|@@|\\\\)/ }.map {|line| line + "\n" }
      when true then diff.split("\n").map {|line| line + "\n" }
      end
      if block_given?
        lines.each{|line| yield line}
      else
        lines.to_enum
      end
    end

    def each_chunk
      old_state = nil
      chunks = inject([]) do |cc, line|
        state = line.each_char.first
        if state == old_state
          cc.last << line
        else
          cc.push line.dup
        end
        old_state = state
        cc
      end

      if block_given?
        chunks.each{|chunk| yield chunk }
      else
        chunks.to_enum
      end
    end

    def tempfile(string)
      t = Tempfile.new('diffy')
      # ensure tempfiles aren't unlinked when GC runs by maintaining a
      # reference to them.
      @tempfiles ||=[]
      @tempfiles.push(t)
      t.print(string)
      t.flush
      t.close
      t.path
    end

    def to_s(format = nil)
      format ||= self.class.default_format
      formats = Format.instance_methods(false).map{|x| x.to_s}
      if formats.include? format.to_s
        enum = self
        enum.extend Format
        enum.send format
      else
        raise ArgumentError,
          "Format #{format.inspect} not found in #{formats.inspect}"
      end
    end
    private

    @@bin = nil
    def diff_bin
      return @@bin if @@bin

      if @@bin = ENV['DIFFY_DIFF']
        # system() trick from Minitest
        raise "Can't execute diff program '#@@bin'" unless system(@@bin, __FILE__, __FILE__)
        return @@bin
      end

      diffs = ['diff', 'ldiff']
      diffs.first << '.exe' if WINDOWS  # ldiff does not have exe extension
      @@bin = diffs.find { |name| system(name, __FILE__, __FILE__) }

      if @@bin.nil?
        raise "Can't find a diff executable in PATH #{ENV['PATH']}"
      end

      @@bin
    end

    # options pass to diff program
    def diff_options
      Array(options[:context] ? "-U #{options[:context]}" : options[:diff])
    end

  end
end

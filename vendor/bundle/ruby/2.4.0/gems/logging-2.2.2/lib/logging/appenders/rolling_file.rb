module Logging::Appenders

  # Accessor / Factory for the RollingFile appender.
  def self.rolling_file( *args )
    fail ArgumentError, '::Logging::Appenders::RollingFile needs a name as first argument.' if args.empty?
    ::Logging::Appenders::RollingFile.new(*args)
  end

  # An appender that writes to a file and ensures that the file size or age
  # never exceeds some user specified level.
  #
  # The goal of this class is to write log messages to a file. When the file
  # age or size exceeds a given limit then the log file is copied and then
  # truncated. The name of the copy indicates it is an older log file.
  #
  # The name of the log file is changed by inserting the age of the log file
  # (as a single number) between the log file name and the extension. If the
  # file has no extension then the number is appended to the filename. Here
  # is a simple example:
  #
  #    /var/log/ruby.log   =>   /var/log/ruby.1.log
  #
  # New log messages will continue to be appended to the same log file
  # (`/var/log/ruby.log` in our example above). The age number for all older
  # log files is incremented when the log file is rolled. The number of older
  # log files to keep can be given, otherwise all the log files are kept.
  #
  # The actual process of rolling all the log file names can be expensive if
  # there are many, many older log files to process.
  #
  # If you do not wish to use numbered files when rolling, you can specify the
  # :roll_by option as 'date'. This will use a date/time stamp to
  # differentiate the older files from one another. If you configure your
  # rolling file appender to roll daily and ignore the file size:
  #
  #    /var/log/ruby.log   =>   /var/log/ruby.20091225.log
  #
  # Where the date is expressed as `%Y%m%d` in the Time#strftime format.
  #
  # NOTE: this class is not safe to use when log messages are written to files
  # on NFS mounts or other remote file system. It should only be used for log
  # files on the local file system. The exception to this is when a single
  # process is writing to the log file; remote file systems are safe to
  # use in this case but still not recommended.
  class RollingFile < ::Logging::Appenders::IO

    # call-seq:
    #    RollingFile.new( name, opts )
    #
    # Creates a new Rolling File Appender. The _name_ is the unique Appender
    # name used to retrieve this appender from the Appender hash. The only
    # required option is the filename to use for creating log files.
    #
    #  [:filename]  The base filename to use when constructing new log
    #               filenames.
    #
    # The "rolling" portion of the filename can be configured via some simple
    # pattern templates. For numbered rolling, you can use {{.%d}}
    #
    #   "logname{{.%d}}.log" => ["logname.log", "logname.1.log", "logname.2.log" ...]
    #   "logname.log{{-%d}}" => ["logname.log", "logname.log-1", "logname.log-2" ...]
    #
    # And for date rolling you can use `strftime` patterns:
    #
    #   "logname{{.%Y%m%d}}.log"            => ["logname.log, "logname.20130626.log" ...]
    #   "logname{{.%Y-%m-%dT%H:%M:%S}}.log" => ["logname.log, "logname.2013-06-26T22:03:31.log" ...]
    #
    # If the defaults suit you fine, just pass in the :roll_by option and use
    # your normal log filename without any pattern template.
    #
    # The following options are optional:
    #
    #  [:layout]    The Layout that will be used by this appender. The Basic
    #               layout will be used if none is given.
    #  [:truncate]  When set to true any existing log files will be rolled
    #               immediately and a new, empty log file will be created.
    #  [:size]      The maximum allowed size (in bytes) of a log file before
    #               it is rolled.
    #  [:age]       The maximum age (in seconds) of a log file before it is
    #               rolled. The age can also be given as 'daily', 'weekly',
    #               or 'monthly'.
    #  [:keep]      The number of rolled log files to keep.
    #  [:roll_by]   How to name the rolled log files. This can be 'number' or
    #               'date'.
    #
    def initialize( name, opts = {} )
      @roller = Roller.new name, opts

      # grab our options
      @size = opts.fetch(:size, nil)
      @size = Integer(@size) unless @size.nil?

      @age_fn = filename + '.age'
      @age_fn_mtime = nil
      @age = opts.fetch(:age, nil)

      # create our `sufficiently_aged?` method
      build_singleton_methods
      FileUtils.touch(@age_fn) if @age && !test(?f, @age_fn)

      # we are opening the file in read/write mode so that a shared lock can
      # be used on the file descriptor => http://pubs.opengroup.org/onlinepubs/009695399/functions/fcntl.html
      @mode = encoding ? "a+:#{encoding}" : 'a+'
      super(name, ::File.new(filename, @mode), opts)

      # if the truncate flag was set to true, then roll
      roll_now = opts.fetch(:truncate, false)
      if roll_now
        copy_truncate
        @roller.roll_files
      end
    end

    # Returns the path to the logfile.
    def filename
      @roller.filename
    end

    # Reopen the connection to the underlying logging destination. If the
    # connection is currently closed then it will be opened. If the connection
    # is currently open then it will be closed and immediately opened.
    def reopen
      @mutex.synchronize {
        if defined?(@io) && @io
          flush
          @io.close rescue nil
        end
        @io = ::File.new(filename, @mode)
      }
      super
      self
    end


  private

    # Returns the file name to use as the temporary copy location. We are
    # using copy-and-truncate semantics for rolling files so that the IO
    # file descriptor remains valid during rolling.
    def copy_file
      @roller.copy_file
    end

    # Returns the modification time of the copy file if one exists. Otherwise
    # returns `nil`.
    def copy_file_mtime
      return nil unless ::File.exist?(copy_file)
      ::File.mtime(copy_file)
    rescue Errno::ENOENT
      nil
    end

    # Write the given _event_ to the log file. The log file will be rolled
    # if the maximum file size is exceeded or if the file is older than the
    # maximum age.
    def canonical_write( str )
      return self if @io.nil?

      str = str.force_encoding(encoding) if encoding && str.encoding != encoding
      @io.flock_sh { @io.write str }

      if roll_required?
        @io.flock? {
          @age_fn_mtime = nil
          copy_truncate if roll_required?
        }
        @roller.roll_files
      end
      self
    rescue StandardError => err
      self.level = :off
      ::Logging.log_internal {"appender #{name.inspect} has been disabled"}
      ::Logging.log_internal_error(err)
    end

    # Returns +true+ if the log file needs to be rolled.
    def roll_required?
      mtime = copy_file_mtime
      return false if mtime && (Time.now - mtime) < 180

      # check if max size has been exceeded
      s = @size ? ::File.size(filename) > @size : false

      # check if max age has been exceeded
      a = sufficiently_aged?

      return (s || a)
    end

    # Copy the contents of the logfile to another file. Truncate the logfile
    # to zero length. This method will set the roll flag so that all the
    # current logfiles will be rolled along with the copied file.
    def copy_truncate
      return unless ::File.exist?(filename)
      FileUtils.concat filename, copy_file
      @io.truncate 0

      # touch the age file if needed
      if @age
        FileUtils.touch @age_fn
        @age_fn_mtime = nil
      end

      @roller.roll = true
    end

    # Returns the modification time of the age file.
    def age_fn_mtime
      @age_fn_mtime ||= ::File.mtime(@age_fn)
    end

    # We use meta-programming here to define the `sufficiently_aged?` method for
    # the rolling appender. The `sufficiently_aged?` method is responsible for
    # determining if the current log file is older than the rolling criteria -
    # daily, weekly, etc.
    #
    # Returns this rolling file appender instance
    def build_singleton_methods
      method =
        case @age
        when 'daily'
          -> {
            now = Time.now
            (now.day != age_fn_mtime.day) || (now - age_fn_mtime) > 86400
          }

        when 'weekly'
          -> { (Time.now - age_fn_mtime) > 604800 }

        when 'monthly'
          -> {
            now = Time.now
            (now.month != age_fn_mtime.month) || (now - age_fn_mtime) > 2678400
          }

        when Integer, String
          @age = Integer(@age)
          -> { (Time.now - age_fn_mtime) > @age }

        else
          -> { false }
        end

      self.define_singleton_method(:sufficiently_aged?, method)
    end

    # Not intended for general consumption, but the Roller class is used
    # internally by the RollingFile appender to roll dem log files according
    # to the user's desires.
    class Roller

      # The magic regex for finding user-defined roller patterns.
      RGXP = %r/{{(([^%]+)?.*?)}}/

      # Create a new roller. See the RollingFile#initialize documentation for
      # the list of options.
      #
      # name - The appender name as a String
      # opts - The options Hash
      #
      def initialize( name, opts )
        # raise an error if a filename was not given
        @fn = opts.fetch(:filename, name)
        raise ArgumentError, 'no filename was given' if @fn.nil?

        if (m = RGXP.match @fn)
          @roll_by = ("#{m[2]}%d" == m[1]) ? :number : :date
        else
          age = opts.fetch(:age, nil)
          size = opts.fetch(:size, nil)

          @roll_by =
              case opts.fetch(:roll_by, nil)
              when 'number'; :number
              when 'date'; :date
              else
                (age && !size) ? :date : :number
              end

          ext = ::File.extname(@fn)
          bn  = ::File.join(::File.dirname(@fn), ::File.basename(@fn, ext))

          @fn = if :date == @roll_by && %w[daily weekly monthly].include?(age)
                  "#{bn}{{.%Y%m%d}}#{ext}"
                elsif :date == @roll_by
                  "#{bn}{{.%Y%m%d-%H%M%S}}#{ext}"
                else
                  "#{bn}{{.%d}}#{ext}"
                end
        end

        @fn = ::File.expand_path(@fn)
        ::Logging::Appenders::File.assert_valid_logfile(filename)

        @roll = false
        @keep = opts.fetch(:keep, nil)
        @keep = Integer(keep) unless keep.nil?
      end

      attr_reader :keep, :roll_by
      attr_accessor :roll

      # Returns the regular log file name without any roller text.
      def filename
        return @filename if defined? @filename
        @filename = (@fn =~ RGXP ?  @fn.sub(RGXP, '') : @fn.dup)
        @filename.freeze
      end

      # Returns the file name to use as the temporary copy location. We are
      # using copy-and-truncate semantics for rolling files so that the IO
      # file descriptor remains valid during rolling.
      def copy_file
        return @copy_file if defined? @copy_file
        @copy_file = filename + '._copy_'
        @copy_file.freeze
      end

      # Returns the glob pattern used to find rolled log files. We use this
      # list for pruning older log files and doing the numbered rolling.
      def glob
        return @glob if defined? @glob
        m = RGXP.match @fn
        @glob = @fn.sub(RGXP, (m[2] ? "#{m[2]}*" : '*'))
        @glob.freeze
      end

      # Returns the format String used to generate rolled file names.
      # Depending upon the `roll_by` type (:date or :number), this String will
      # be processed by `sprintf` or `Time#strftime`.
      def format
        return @format if defined? @format
        m = RGXP.match @fn
        @format = @fn.sub(RGXP, m[1])
        @format.freeze
      end

      # Roll the log files. This method will collect the list of rolled files
      # and then pass that list to either `roll_by_number` or `roll_by_date`
      # to perform the actual rolling.
      #
      # Returns nil
      def roll_files
        return unless roll && ::File.exist?(copy_file)

        files = Dir.glob(glob)
        files.delete copy_file

        self.send "roll_by_#{roll_by}", files

        nil
      ensure
        self.roll = false
      end

      # Roll the list of log files optionally removing older files. The "older
      # files" are determined by extracting the number from the log file name
      # and order by the number.
      #
      # files - The Array of filename Strings
      #
      # Returns nil
      def roll_by_number( files )
        @number_rgxp ||= Regexp.new(@fn.sub(RGXP, '\2(\d+)'))

        # sort the files in reverse order based on their count number
        files = files.sort do |a,b|
                  a = Integer(@number_rgxp.match(a)[1])
                  b = Integer(@number_rgxp.match(b)[1])
                  b <=> a
                end

        # for each file, roll its count number one higher
        files.each do |fn|
          cnt = Integer(@number_rgxp.match(fn)[1])
          if keep && cnt >= keep
            ::File.delete fn
            next
          end
          ::File.rename fn, sprintf(format, cnt+1)
        end

        # finally rename the copied log file
        ::File.rename(copy_file, sprintf(format, 1))
      end

      # Roll the list of log files optionally removing older files. The "older
      # files" are determined by the mtime of the log files. So touching log
      # files or otherwise messing with them will screw this up.
      #
      # files - The Array of filename Strings
      #
      # Returns nil
      def roll_by_date( files )
        length = files.length

        if keep && length >= keep
          files = files.sort do |a,b|
                    a = ::File.mtime(a)
                    b = ::File.mtime(b)
                    b <=> a
                  end
          files.last(length-keep+1).each { |fn| ::File.delete fn }
        end

        # rename the copied log file
        ::File.rename(copy_file, Time.now.strftime(format))
      end
    end
  end
end

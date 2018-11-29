
require 'thread'
require 'rbconfig'

# --------------------------------------------------------------------------
class String

  # call-seq:
  #    shrink( width, ellipses = '...' )    #=> string
  #
  # Shrink the size of the current string to the given _width_ by removing
  # characters from the middle of the string and replacing them with
  # _ellipses_. If the _width_ is greater than the length of the string, the
  # string is returned unchanged. If the _width_ is less than the length of
  # the _ellipses_, then the _ellipses_ are returned.
  #
  def shrink( width, ellipses = '...')
    raise ArgumentError, "width cannot be negative: #{width}" if width < 0

    return self if length <= width

    remove = length - width + ellipses.length
    return ellipses.dup if remove >= length

    left_end = (length + 1 - remove) / 2
    right_start = left_end + remove

    left = self[0,left_end]
    right = self[right_start,length-right_start]

    left << ellipses << right
  end
end

# --------------------------------------------------------------------------
class Module

  # call-seq:
  #    logger_name    #=> string
  #
  # Returns a predictable logger name for the current module or class. If
  # used within an anonymous class, the first non-anonymous class name will
  # be used as the logger name. If used within a meta-class, the name of the
  # actual class will be used as the logger name. If used within an
  # anonymous module, the string 'anonymous' will be returned.
  #
  def logger_name
    return name unless name.nil? or name.empty?

    # check if this is a metaclass (or eigenclass)
    if ancestors.include? Class
      inspect =~ %r/#<Class:([^#>]+)>/
      return $1
    end

    # see if we have a superclass
    if respond_to? :superclass
      return superclass.logger_name
    end

    # we are an anonymous module
    ::Logging.log_internal(-2) {
      'cannot return a predictable, unique name for anonymous modules'
    }
    return 'anonymous'
  end
end

# --------------------------------------------------------------------------
class File

  # Returns <tt>true</tt> if another process holds an exclusive lock on the
  # file. Returns <tt>false</tt> if this is not the case.
  #
  # If a <tt>block</tt> of code is passed to this method, it will be run iff
  # this process can obtain an exclusive lock on the file. The block will be
  # run while this lock is held, and the exclusive lock will be released when
  # the method returns.
  #
  # The exclusive lock is requested in a non-blocking mode. This method will
  # return immediately (and the block will not be executed) if an exclusive
  # lock cannot be obtained.
  #
  def flock?
    status = flock(LOCK_EX|LOCK_NB)
    case status
    when false; true
    when 0; block_given? ? yield : false
    else
      raise SystemCallError, "flock failed with status: #{status}"
    end
  ensure
    flock LOCK_UN
  end

  # Execute a <tt>block</tt> in the context of a shared lock on this file. A
  # shared lock will be obtained on the file, the block executed, and the lock
  # released.
  #
  def flock_sh
    flock LOCK_SH
    yield
  ensure
    flock LOCK_UN
  end

  # :stopdoc:
  conf = defined?(RbConfig) ? RbConfig::CONFIG : Config::CONFIG
  if conf['host_os'] =~ /mswin|windows|cygwin|mingw/i
    # don't lock files on windows
    undef :flock?, :flock_sh
    def flock?() yield; end
    def flock_sh() yield; end
  end
  # :startdoc:

end

# --------------------------------------------------------------------------
module FileUtils

  # Concatenate the contents of the _src_ file to the end of the _dest_ file.
  # If the _dest_ file does not exist, then the _src_ file is copied to the
  # _dest_ file using +copy_file+.
  #
  def concat( src, dest )
    if File.exist?(dest)
      bufsize = File.stat(dest).blksize || 8192
      buffer = String.new

      File.open(dest, 'a') { |d|
        File.open(src, 'r') { |r|
          while bytes = r.read(bufsize, buffer)
            d.syswrite bytes
          end
        }
      }
    else
      copy_file(src, dest)
    end
  end
  module_function :concat
end

# --------------------------------------------------------------------------
class ReentrantMutex < Mutex

  def initialize
    super
    @locker = nil
  end

  alias_method :original_synchronize, :synchronize

  def synchronize
    if @locker == Thread.current
      yield
    else
      original_synchronize {
        begin
          @locker = Thread.current
          yield
        ensure
          @locker = nil
        end
      }
    end
  end
end  # ReentrantMutex


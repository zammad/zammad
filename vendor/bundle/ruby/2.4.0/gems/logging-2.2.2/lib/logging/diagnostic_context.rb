
module Logging

  # A Mapped Diagnostic Context, or MDC in short, is an instrument used to
  # distinguish interleaved log output from different sources. Log output is
  # typically interleaved when a server handles multiple clients
  # near-simultaneously.
  #
  # Interleaved log output can still be meaningful if each log entry from
  # different contexts had a distinctive stamp. This is where MDCs come into
  # play.
  #
  # The MDC provides a hash of contextual messages that are identified by
  # unique keys. These unique keys are set by the application and appended
  # to log messages to identify groups of log events. One use of the Mapped
  # Diagnostic Context is to store HTTP request headers associated with a Rack
  # request. These headers can be included with all log messages emitted while
  # generating the HTTP response.
  #
  # When configured to do so, PatternLayout instances will automatically
  # retrieve the mapped diagnostic context for the current thread with out any
  # user intervention. This context information can be used to track user
  # sessions in a Rails application, for example.
  #
  # Note that MDCs are managed on a per thread basis. MDC operations such as
  # `[]`, `[]=`, and `clear` affect the MDC of the current thread only. MDCs
  # of other threads remain unaffected.
  #
  # By default, when a new thread is created it will inherit the context of
  # its parent thread. However, the `inherit` method may be used to inherit
  # context for any other thread in the application.
  #
  module MappedDiagnosticContext
    extend self

    # The name used to retrieve the MDC from thread-local storage.
    NAME = :logging_mapped_diagnostic_context

    # The name used to retrieve the MDC stack from thread-local storage.
    STACK_NAME = :logging_mapped_diagnostic_context_stack

    # Public: Put a context value as identified with the key parameter into
    # the current thread's context map.
    #
    # key   - The String identifier for the context.
    # value - The String value to store.
    #
    # Returns the value.
    #
    def []=( key, value )
      clear_context
      peek.store(key.to_s, value)
    end

    # Public: Get the context value identified with the key parameter.
    #
    # key - The String identifier for the context.
    #
    # Returns the value associated with the key or nil if there is no value
    # present.
    #
    def []( key )
      context.fetch(key.to_s, nil)
    end

    # Public: Remove the context value identified with the key parameter.
    #
    # key - The String identifier for the context.
    #
    # Returns the value associated with the key or nil if there is no value
    # present.
    #
    def delete( key )
      clear_context
      peek.delete(key.to_s)
    end

    # Public: Add all the key/value pairs from the given hash to the current
    # mapped diagnostic context. The keys will be converted to strings.
    # Existing keys of the same name will be overwritten.
    #
    # hash - The Hash of values to add to the current context.
    #
    # Returns this context.
    #
    def update( hash )
      clear_context
      sanitize(hash, peek)
      self
    end

    # Public: Push a new Hash of key/value pairs onto the stack of contexts.
    #
    # hash - The Hash of values to push onto the context stack.
    #
    # Returns this context.
    # Raises an ArgumentError if hash is not a Hash.
    #
    def push( hash )
      clear_context
      stack << sanitize(hash)
      self
    end

    # Public: Remove the most recently pushed Hash from the stack of contexts.
    # If no contexts have been pushed then no action will be taken. The
    # default context cannot be popped off the stack; please use the `clear`
    # method if you want to remove all key/value pairs from the context.
    #
    # Returns nil or the Hash removed from the stack.
    #
    def pop
      return unless Thread.current.thread_variable_get(STACK_NAME)
      return unless stack.length > 1
      clear_context
      stack.pop
    end


    # Public: Clear all mapped diagnostic information if any. This method is
    # useful in cases where the same thread can be potentially used over and
    # over in different unrelated contexts.
    #
    # Returns the MappedDiagnosticContext.
    #
    def clear
      clear_context
      Thread.current.thread_variable_set(STACK_NAME, nil)
      self
    end

    # Public: Inherit the diagnostic context of another thread. In the vast
    # majority of cases the other thread will the parent that spawned the
    # current thread. The diagnostic context from the parent thread is cloned
    # before being inherited; the two diagnostic contexts can be changed
    # independently.
    #
    # Returns the MappedDiagnosticContext.
    #
    def inherit( obj )
      case obj
      when Hash
        Thread.current.thread_variable_set(STACK_NAME, [obj.dup])
      when Thread
        return if Thread.current == obj
        DIAGNOSTIC_MUTEX.synchronize do
          if hash = obj.thread_variable_get(STACK_NAME)
            Thread.current.thread_variable_set(STACK_NAME, [flatten(hash)])
          end
        end
      end

      self
    end

    # Returns the Hash acting as the storage for this MappedDiagnosticContext.
    # A new storage Hash is created for each Thread running in the
    # application.
    #
    def context
      c = Thread.current.thread_variable_get(NAME)

      if c.nil?
        c = if Thread.current.thread_variable_get(STACK_NAME)
          flatten(stack)
        else
          Hash.new
        end
        Thread.current.thread_variable_set(NAME, c)
      end

      return c
    end

    # Returns the stack of Hash objects that are storing the diagnostic
    # context information. This stack is guarnteed to always contain at least
    # one Hash.
    #
    def stack
      s = Thread.current.thread_variable_get(STACK_NAME)
      if s.nil?
        s = [{}]
        Thread.current.thread_variable_set(STACK_NAME, s)
      end
      return s
    end

    # Returns the most current Hash from the stack of contexts.
    #
    def peek
      stack.last
    end

    # Remove the flattened context.
    #
    def clear_context
      Thread.current.thread_variable_set(NAME, nil)
      self
    end

    # Given a Hash convert all keys into Strings. The values are not altered
    # in any way. The converted keys and their values are stored in the target
    # Hash if provided. Otherwise a new Hash is created and returned.
    #
    # hash   - The Hash of values to push onto the context stack.
    # target - The target Hash to store the key value pairs.
    #
    # Returns a new Hash with all keys converted to Strings.
    # Raises an ArgumentError if hash is not a Hash.
    #
    def sanitize( hash, target = {} )
      unless hash.is_a?(Hash)
        raise ArgumentError, "Expecting a Hash but received a #{hash.class.name}"
      end

      hash.each { |k,v| target[k.to_s] = v }
      return target
    end

    # Given an Array of Hash objects, flatten all the key/value pairs from the
    # Hash objects in the ary into a single Hash. The flattening occurs left
    # to right. So that the key/value in the very last Hash overrides any
    # other key from the previous Hash objcts.
    #
    # ary - An Array of Hash objects.
    #
    # Returns a Hash.
    #
    def flatten( ary )
      return ary.first.dup if ary.length == 1

      hash = {}
      ary.each { |h| hash.update h }
      return hash
    end

  end  # MappedDiagnosticContext


  # A Nested Diagnostic Context, or NDC in short, is an instrument to
  # distinguish interleaved log output from different sources. Log output is
  # typically interleaved when a server handles multiple clients
  # near-simultaneously.
  #
  # Interleaved log output can still be meaningful if each log entry from
  # different contexts had a distinctive stamp. This is where NDCs come into
  # play.
  #
  # The NDC is a stack of contextual messages that are pushed and popped by
  # the client as different contexts are encountered in the application. When a
  # new context is entered, the client will `push` a new message onto the NDC
  # stack. This message appears in all log messages. When this context is
  # exited, the client will call `pop` to remove the message.
  #
  # * Contexts can be nested
  # * When entering a context, call `Logging.ndc.push`
  # * When leaving a context, call `Logging.ndc.pop`
  # * Configure the PatternLayout to log context information
  #
  # There is no penalty for forgetting to match each push operation with a
  # corresponding pop, except the obvious mismatch between the real
  # application context and the context set in the NDC.
  #
  # When configured to do so, PatternLayout instance will automatically
  # retrieve the nested diagnostic context for the current thread with out any
  # user intervention. This context information can be used to track user
  # sessions in a Rails application, for example.
  #
  # Note that NDCs are managed on a per thread basis. NDC operations such as
  # `push`, `pop`, and `clear` affect the NDC of the current thread only. NDCs
  # of other threads remain unaffected.
  #
  # By default, when a new thread is created it will inherit the context of
  # its parent thread. However, the `inherit` method may be used to inherit
  # context for any other thread in the application.
  #
  module NestedDiagnosticContext
    extend self

    # The name used to retrieve the NDC from thread-local storage.
    NAME = :logging_nested_diagnostic_context

    # Public: Push new diagnostic context information for the current thread.
    # The contents of the message parameter is determined solely by the
    # client.
    #
    # message - The message String to add to the current context.
    #
    # Returns the current NestedDiagnosticContext.
    #
    def push( message )
      context.push(message)
      if block_given?
        begin
          yield
        ensure
          context.pop
        end
      end
      self
    end
    alias_method :<<, :push

    # Public: Clients should call this method before leaving a diagnostic
    # context. The returned value is the last pushed message. If no
    # context is available then `nil` is returned.
    #
    # Returns the last pushed diagnostic message String or nil if no messages
    # exist.
    #
    def pop
      context.pop
    end

    # Public: Looks at the last diagnostic context at the top of this NDC
    # without removing it. The returned value is the last pushed message. If
    # no context is available then `nil` is returned.
    #
    # Returns the last pushed diagnostic message String or nil if no messages
    # exist.
    #
    def peek
      context.last
    end

    # Public: Clear all nested diagnostic information if any. This method is
    # useful in cases where the same thread can be potentially used over and
    # over in different unrelated contexts.
    #
    # Returns the NestedDiagnosticContext.
    #
    def clear
      Thread.current.thread_variable_set(NAME, nil)
      self
    end

    # Public: Inherit the diagnostic context of another thread. In the vast
    # majority of cases the other thread will the parent that spawned the
    # current thread. The diagnostic context from the parent thread is cloned
    # before being inherited; the two diagnostic contexts can be changed
    # independently.
    #
    # Returns the NestedDiagnosticContext.
    #
    def inherit( obj )
      case obj
      when Array
        Thread.current.thread_variable_set(NAME, obj.dup)
      when Thread
        return if Thread.current == obj
        DIAGNOSTIC_MUTEX.synchronize do
          Thread.current.thread_variable_set(NAME, obj.thread_variable_get(NAME).dup) if obj.thread_variable_get(NAME)
        end
      end

      self
    end

    # Returns the Array acting as the storage stack for this
    # NestedDiagnosticContext. A new storage Array is created for each Thread
    # running in the application.
    #
    def context
      c = Thread.current.thread_variable_get(NAME)
      if c.nil?
        c = Array.new
        Thread.current.thread_variable_set(NAME, c)
      end
      return c
    end
  end  # NestedDiagnosticContext


  # Public: Accessor method for getting the current Thread's
  # MappedDiagnosticContext.
  #
  # Returns MappedDiagnosticContext
  #
  def self.mdc() MappedDiagnosticContext end

  # Public: Accessor method for getting the current Thread's
  # NestedDiagnosticContext.
  #
  # Returns NestedDiagnosticContext
  #
  def self.ndc() NestedDiagnosticContext end

  # Public: Convenience method that will clear both the Mapped Diagnostic
  # Context and the Nested Diagnostic Context of the current thread. If the
  # `all` flag passed to this method is true, then the diagnostic contexts for
  # _every_ thread in the application will be cleared.
  #
  # all - Boolean flag used to clear the context of every Thread (default is false)
  #
  # Returns the Logging module.
  #
  def self.clear_diagnostic_contexts( all = false )
    if all
      DIAGNOSTIC_MUTEX.synchronize do
        Thread.list.each do |t|
          t.thread_variable_set(MappedDiagnosticContext::NAME, nil)       if t.thread_variable?(MappedDiagnosticContext::NAME)
          t.thread_variable_set(NestedDiagnosticContext::NAME, nil)       if t.thread_variable?(NestedDiagnosticContext::NAME)
          t.thread_variable_set(MappedDiagnosticContext::STACK_NAME, nil) if t.thread_variable?(MappedDiagnosticContext::STACK_NAME)
        end
      end
    else
      MappedDiagnosticContext.clear
      NestedDiagnosticContext.clear
    end

    self
  end

  DIAGNOSTIC_MUTEX = Mutex.new
end

# :stopdoc:
Logging::INHERIT_CONTEXT =
  if ENV.key?("LOGGING_INHERIT_CONTEXT")
    case ENV["LOGGING_INHERIT_CONTEXT"].downcase
    when 'false', 'no', '0'; false
    when false, nil; false
    else true end
  else
    true
  end

if Logging::INHERIT_CONTEXT
  class Thread
    class << self

      %w[new start fork].each do |m|
        class_eval <<-__, __FILE__, __LINE__
          alias_method :_orig_#{m}, :#{m}
          private :_orig_#{m}
          def #{m}( *a, &b )
            create_with_logging_context(:_orig_#{m}, *a ,&b)
          end
        __
      end

    private

      # In order for the diagnostic contexts to behave properly we need to
      # inherit state from the parent thread. The only way I have found to do
      # this in Ruby is to override `new` and capture the contexts from the
      # parent Thread at the time the child Thread is created. The code below does
      # just this. If there is a more idiomatic way of accomplishing this in Ruby,
      # please let me know!
      #
      # Also, great care is taken in this code to ensure that a reference to the
      # parent thread does not exist in the binding associated with the block
      # being executed in the child thread. The same is true for the parent
      # thread's mdc and ndc. If any of those references end up in the binding,
      # then they cannot be garbage collected until the child thread exits.
      #
      def create_with_logging_context( m, *a, &b )
        mdc, ndc = nil

        if Thread.current.thread_variable_get(Logging::MappedDiagnosticContext::STACK_NAME)
          mdc = Logging::MappedDiagnosticContext.context.dup
        end

        if Thread.current.thread_variable_get(Logging::NestedDiagnosticContext::NAME)
          ndc = Logging::NestedDiagnosticContext.context.dup
        end

        # This calls the actual `Thread#new` method to create the Thread instance.
        # If your memory profiling tool says this method is leaking memory, then
        # you are leaking Thread instances somewhere.
        self.send(m, *a) { |*args|
          Logging::MappedDiagnosticContext.inherit(mdc)
          Logging::NestedDiagnosticContext.inherit(ndc)
          b.call(*args)
        }
      end

    end
  end
end
# :startdoc:


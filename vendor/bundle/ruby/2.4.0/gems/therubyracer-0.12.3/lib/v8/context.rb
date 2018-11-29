# -*- coding: utf-8 -*-
require 'stringio'
module V8
  # All JavaScript must be executed in a context. This context consists of a global scope containing the
  # standard JavaScript objects¨and functions like Object, String, Array, as well as any objects or
  # functions from Ruby which have been embedded into it from the containing enviroment. E.g.
  #
  #     V8::Context.new do |cxt|
  #         cxt['num'] = 5
  #         cxt.eval('num + 5') #=> 10
  #     end
  #
  # The same object may appear in any number of contexts, but only one context may be executing JavaScript code
  # in any given thread. If a new context is opened in a thread in which a context is already opened, the second
  # context will "mask" the old context e.g.
  #
  #   six = 6
  #   Context.new do |cxt|
  #     cxt['num'] = 5
  #     cxt.eval('num') # => 5
  #     Context.new do |cxt|
  #       cxt['num'] = 10
  #       cxt.eval('num') # => 10
  #       cxt.eval('++num') # => 11
  #     end
  #     cxt.eval('num') # => 5
  #   end
  class Context
    include V8::Error::Try

    # @!attribute [r] conversion
    #   @return [V8::Conversion] conversion behavior for this context
    attr_reader :conversion

    # @!attrribute [r] access
    #   @return [V8::Access] Ruby access behavior for this context
    attr_reader :access

    # @!attribute [r] native
    #   @return [V8::C::Context] the underlying C++ object
    attr_reader :native

    # @!attribute [r] timeout
    #   @return [Number] maximum execution time in milliseconds for scripts executed in this context
    attr_reader :timeout

    # Creates a new context.
    #
    # If passed the `:with` option, that object will be used as
    # the global scope of the newly creating context. e.g.
    #
    #     scope = Object.new
    #     def scope.hello; "Hi"; end
    #     V8::Context.new(:with => scope) do |cxt|
    #       cxt['hello'] #=> 'Hi'
    #     end
    #
    # If passed the `:timeout` option, every eval will timeout once
    #   N milliseconds elapse
    #
    # @param [Hash<Symbol, Object>] options initial context configuration
    #  * :with scope serves as the global scope of the new context
    # @yield [V8::Context] the newly created context
    def initialize(options = {})
      @conversion = Conversion.new
      @access = Access.new
      @timeout = options[:timeout]
      if global = options[:with]
        Context.new.enter do
          global_template = global.class.to_template.InstanceTemplate()
          @native = V8::C::Context::New(nil, global_template)
        end
        enter {link global, @native.Global()}
      else
        V8::C::Locker() do
          @native = V8::C::Context::New()
        end
      end
      yield self if block_given?
    end

    # Compile and execute a string of JavaScript source.
    #
    # If `source` is an IO object it will be read fully before being evaluated
    #
    # @param [String,IO] source the source code to compile and execute
    # @param [String] filename the name to use for this code when generating stack traces
    # @param [Integer] line the line number to start with
    # @return [Object] the result of the evaluation
    def eval(source, filename = '<eval>', line = 1)
      if IO === source || StringIO === source
        source = source.read
      end
      enter do
        script = try { V8::C::Script::New(source.to_s, filename.to_s) }
        if @timeout
          to_ruby try {script.RunWithTimeout(@timeout)}
        else
          to_ruby try {script.Run()}
        end
      end
    end

    # Read a value from the global scope of this context
    #
    # @param [Object] key the name of the value to read
    # @return [Object] value the value at `key`
    def [](key)
      enter do
        to_ruby(@native.Global().Get(to_v8(key)))
      end
    end

    # Binds `value` to the name `key` in the global scope of this context.
    #
    # @param [Object] key the name to bind to
    # @param [Object] value the value to bind
    def []=(key, value)
      enter do
        @native.Global().Set(to_v8(key), to_v8(value))
      end
      return value
    end

    # Destroy this context and release any internal references it may
    # contain to embedded Ruby objects.
    #
    # A disposed context may never again be used for anything, and all
    # objects created with it will become unusable.
    def dispose
      return unless @native
      @native.Dispose()
      @native = nil
      V8::C::V8::ContextDisposedNotification()
      def self.enter
        fail "cannot enter a context which has already been disposed"
      end
    end

    # Returns this context's global object. This will be a `V8::Object`
    # if no scope was provided or just an `Object` if a Ruby object
    # is serving as the global scope.
    #
    # @return [Object] scope the context's global scope.
    def scope
      enter { to_ruby @native.Global() }
    end

    # Converts a v8 C++ object into its ruby counterpart. This is method
    # is used to translate all values passed to Ruby from JavaScript, either
    # as return values or as callback parameters.
    #
    # @param [V8::C::Object] v8_object the native c++ object to convert.
    # @return [Object] to pass to Ruby
    # @see V8::Conversion for how to customize and extend this mechanism
    def to_ruby(v8_object)
      @conversion.to_ruby(v8_object)
    end

    # Converts a Ruby object into a native v8 C++ object. This method is
    # used to translate all values passed to JavaScript from Ruby, either
    # as return value or as callback parameters.
    #
    # @param [Object] ruby_object the Ruby object to convert
    # @return [V8::C::Object] to pass to V8
    # @see V8::Conversion for customizing and extending this mechanism
    def to_v8(ruby_object)
      @conversion.to_v8(ruby_object)
    end

    # Marks a Ruby object and a v8 C++ Object as being the same. In other
    # words whenever `ruby_object` is passed to v8, the result of the
    # conversion should be `v8_object`. Conversely, whenever `v8_object`
    # is passed to Ruby, the result of the conversion should be `ruby_object`.
    # The Ruby Racer uses this mechanism to maintain referential integrity
    # between Ruby and JavaScript peers
    #
    # @param [Object] ruby_object the Ruby half of the object identity
    # @param [V8::C::Object] v8_object the V8 half of the object identity.
    # @see V8::Conversion::Identity
    def link(ruby_object, v8_object)
      @conversion.equate ruby_object, v8_object
    end

    # Links `ruby_object` and `v8_object` inside the currently entered
    # context. This is an error if no context has been entered.
    #
    # @param [Object] ruby_object the Ruby half of the object identity
    # @param [V8::C::Object] v8_object the V8 half of the object identity.
    def self.link(ruby_object, v8_object)
      current.link ruby_object, v8_object
    end

    # Run some Ruby code in the context of this context.
    #
    # This will acquire the V8 interpreter lock (possibly blocking
    # until it is available), and prepare V8 for JavaScript execution.
    #
    # Only one context may be running at a time per thread.
    #
    # @return [Object] the result of executing `block`
    def enter(&block)
      if !entered?
        lock_scope_and_enter(&block)
      else
        yield
      end
    end

    # Indicates if this context is the currently entered context
    #
    # @return true if this context is currently entered
    def entered?
      Context.current == self
    end

    # Get the currently entered context.
    #
    # @return [V8::Context] currently entered context, nil if none entered.
    def self.current
      Thread.current[:v8_context]
    end

    # Compile and execute the contents of the file with path `filename`
    # as JavaScript code.
    #
    # @param [String] filename path to the file to execute.
    # @return [Object] the result of the evaluation.
    def load(filename)
      File.open(filename) do |file|
        self.eval file, filename
      end
    end

    private

    def self.current=(context)
      Thread.current[:v8_context] = context
    end

    def lock_scope_and_enter
      current = Context.current
      Context.current = self
      V8::C::Locker() do
        V8::C::HandleScope() do
          begin
            @native.Enter()
            yield if block_given?
          ensure
            @native.Exit()
          end
        end
      end
    ensure
      Context.current = current
    end
  end
end

class V8::Object
  include Enumerable
  attr_reader :native
  alias_method :to_v8, :native

  def initialize(native = nil)
    @context = V8::Context.current or fail "tried to initialize a #{self.class} without being in an entered V8::Context"
    @native = block_given? ? yield : native || V8::C::Object::New()
    @context.link self, @native
  end

  def [](key)
    @context.enter do
      @context.to_ruby @native.Get(@context.to_v8(key))
    end
  end

  def []=(key, value)
    @context.enter do
      @native.Set(@context.to_v8(key), @context.to_v8(value))
    end
    return value
  end

  def keys
    @context.enter do
      names = @native.GetPropertyNames()
      0.upto( names.Length() - 1).to_enum.map {|i| @context.to_ruby names.Get(i)}
    end
  end

  def values
    @context.enter do
      names = @native.GetPropertyNames()
      0.upto( names.Length() - 1).to_enum.map {|i| @context.to_ruby @native.Get(names.Get(i))}
    end
  end

  def each
    @context.enter do
      names = @native.GetPropertyNames()
      0.upto(names.Length() - 1) do |i|
        name = names.Get(i)
        yield @context.to_ruby(name), @context.to_ruby(@native.Get(name))
      end
    end
  end

  def to_s
    @context.enter do
      @context.to_ruby @native.ToString()
    end
  end

  def respond_to?(method)
    super or self[method] != nil
  end

  def method_missing(name, *args, &block)
    if name.to_s =~ /(.*)=$/
      if args.length > 1
        self[$1] = args
        return args
      else
        self[$1] = args.first
        return args
      end
    end
    return super(name, *args, &block) unless self.respond_to?(name)
    property = self[name]
    if property.kind_of?(V8::Function)
      property.methodcall(self, *args)
    elsif args.empty?
      property
    else
      raise ArgumentError, "wrong number of arguments (#{args.length} for 0)" unless args.empty?
    end
  end
end
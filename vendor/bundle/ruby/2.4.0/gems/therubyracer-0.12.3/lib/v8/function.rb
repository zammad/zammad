class V8::Function < V8::Object
  include V8::Error::Try

  def initialize(native = nil)
    super do
      native || V8::C::FunctionTemplate::New().GetFunction()
    end
  end

  def methodcall(this, *args)
    @context.enter do
      this ||= @context.native.Global()
      @context.to_ruby try {native.Call(@context.to_v8(this), args.map {|a| @context.to_v8 a})}
    end
  end

  def call(*args)
    @context.enter do
      methodcall @context.native.Global(), *args
    end
  end

  def new(*args)
    @context.enter do
      @context.to_ruby try {native.NewInstance(args.map {|a| @context.to_v8 a})}
    end
  end
end
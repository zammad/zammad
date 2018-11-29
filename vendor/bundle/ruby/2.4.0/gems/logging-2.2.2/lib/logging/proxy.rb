
module Logging

  # Defines a Proxy that will log all method calls on the proxied object. This
  # class uses +method_missing+ on a "blank slate" object to intercept all
  # method calls. The method name being called and the arguments are all
  # logged to the proxied object's logger instance. The log level and other
  # settings for the proxied object are honored by the Proxy instance.
  #
  # If you want, you can also supply your own +method_missing+ code as a block
  # to the constructor.
  #
  #   Proxy.new(object) do |name, *args, &block|
  #     # code to be executed before the proxied method
  #     result = @object.send(name, *args, &block)
  #     # code to be executed after the proxied method
  #     result   # <-- always return the result
  #   end
  #
  # The proxied object is available as the "@object" variable. The logger is
  # available as the "@logger" variable.
  #
  class Proxy

    # :stopdoc:
    KEEPERS = %r/^__|^object_id$|^initialize$/
    instance_methods(true).each { |m| undef_method m unless m[KEEPERS] }
    private_instance_methods(true).each { |m| undef_method m unless m[KEEPERS] }
    # :startdoc:

    # Create a new proxy for the given _object_. If an optional _block_ is
    # given it will be called before the proxied method. This _block_ will
    # replace the +method_missing+ implementation
    #
    def initialize( object, &block )
      Kernel.raise ArgumentError, "Cannot proxy nil" if nil.equal? object

      @object = object
      @leader = @object.is_a?(Class) ? "#{@object.name}." : "#{@object.class.name}#"
      @logger = Logging.logger[object]

      if block
        eigenclass = class << self; self; end
        eigenclass.__send__(:define_method, :method_missing, &block)
      end
    end

    # All hail the magic of method missing. Here is where we are going to log
    # the method call and then forward to the proxied object. The return value
    # from the proxied objet method call is passed back.
    #
    def method_missing( name, *args, &block )
      @logger << "#@leader#{name}(#{args.inspect[1..-2]})\n"
      @object.send(name, *args, &block)
    end

  end  # Proxy
end  # Logging


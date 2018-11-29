class VerbHandler < YARD::Handlers::Ruby::Base
  handles method_call(:put), method_call(:post), method_call(:get)

  def process
    name = statement.parameters.first.jump(:ident).source

    verb = YARD::CodeObjects::MethodObject.new(namespace, name)
    register(verb)
    verb.dynamic = true
    verb.docstring.add_tag(YARD::Tags::Tag.new(:return, "Success of this call", "Boolean"))

    verb.signature = "def #{name}=(options = {})"
    verb.parameters = [['options', {}]]
    verb.docstring.add_tag(YARD::Tags::Tag.new(:param, "Options to pass to the request", "Hash", "options"))
  end
end

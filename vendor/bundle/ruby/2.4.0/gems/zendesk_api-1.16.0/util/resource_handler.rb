require 'zendesk_api'

class ResourceHandler < YARD::Handlers::Ruby::Base
  handles method_call(:has), method_call(:has_many)

  def process
    many = statement.jump(:ident).source == "has_many"

    klass = get_klass(statement)

    if klass
      begin
        klass = klass.split("::").inject(ZendeskAPI) do |p, k|
          p.const_get(k)
        end
      rescue NameError
        parent = walk_namespace(namespace)
        klass = parent.const_get(klass)
      end

      name = statement.parameters.first.jump(:ident).source
    else
      klass = statement.parameters.first.source

      begin
        klass = ZendeskAPI.const_get(klass)
      rescue NameError
        parent = walk_namespace(namespace)
        klass = parent.const_get(klass)
      end

      name = many ? klass.resource_name : klass.singular_resource_name
    end

    reader = YARD::CodeObjects::MethodObject.new(namespace, name)
    register(reader)
    reader.dynamic = true
    reader.docstring.add_tag(YARD::Tags::Tag.new(:return, "The associated object", klass.name))

    if many
      reader.signature = "def #{name}=(options = {})"
      reader.parameters = [['options', {}]]
      reader.docstring.add_tag(YARD::Tags::Tag.new(:param, "Options to pass to the collection object", "Hash", "options"))
    end

    writer = YARD::CodeObjects::MethodObject.new(namespace, "#{name}=")
    register(writer)
    writer.signature = "def #{name}=(value)"
    writer.parameters = [['value', nil]]
    writer.dynamic = true
    writer.docstring.add_tag(YARD::Tags::Tag.new(:return, "The associated object", klass.name))
    writer.docstring.add_tag(YARD::Tags::Tag.new(:param, "The associated object or its attributes", "Hash or #{klass.name}", "value"))
  end

  def walk_namespace(namespace)
    namespace.to_s.split('::').inject(ZendeskAPI) do |klass, namespace|
      klass.const_get(namespace)
    end
  end

  def get_klass(statement)
    statement.traverse do |node|
      if node.type == :assoc && node.jump(:kw).source == "class"
        node.traverse do |value|
          if value.type == :const_path_ref || value.type == :var_ref
            return value.source
          end
        end
      end
    end

    nil
  end
end

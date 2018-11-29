require 'zendesk_api/helpers'

module ZendeskAPI
  # Represents an association between two resources
  # @private
  class Association
    class << self
      def namespaces
        [ZendeskAPI] + ZendeskAPI::DataNamespace.descendants
      end

      def class_from_namespace(klass_as_string)
        namespaces.each do |ns|
          if module_defines_class?(ns, klass_as_string)
            return ns.const_get(klass_as_string)
          end
        end

        nil
      end

      # 1.9+ changed default to search ancestors, added flag to disable behavior.
      def module_defines_class?(mod, klass_as_string)
        if RUBY_VERSION < '1.9'
          mod.const_defined?(klass_as_string)
        else
          mod.const_defined?(klass_as_string, false)
        end
      end
    end

    # @return [Hash] Options passed into the association
    attr_reader :options

    # Options to pass in
    # * class - Required
    # * parent - Parent instance
    # * path - Optional path instead of resource name
    def initialize(options = {})
      @options = SilentMash.new(options)
    end

    # Generate a path to the resource.
    # id and <parent>_id attributes will be deleted from passed in options hash if they are used in the built path.
    # Arguments that can be passed in:
    # An instance, any resource instance
    # Hash Options:
    # * with_parent - Include the parent path (false by default)
    # * with_id - Include the instance id, if possible (true)
    def generate_path(*args)
      options = SilentMash.new(:with_id => true)
      if args.last.is_a?(Hash)
        original_options = args.pop
        options.merge!(original_options)
      end

      instance = args.first

      namespace = @options[:class].to_s.split("::")
      namespace[-1] = @options[:class].resource_path

      # Remove components without path information
      ignorable_namespace_strings.each { |ns| namespace.delete(ns) }
      has_parent = namespace.size > 1 || (options[:with_parent] && @options.parent)

      if has_parent
        parent_class = @options.parent ? @options.parent.class : Association.class_from_namespace(ZendeskAPI::Helpers.modulize_string(namespace[0]))
        parent_namespace = build_parent_namespace(parent_class, instance, options, original_options)
        namespace[1..1] = parent_namespace if parent_namespace
        namespace[0] = parent_class.resource_path
      else
        namespace[0] = @options.path || @options[:class].resource_path
      end

      if id = extract_id(instance, options, original_options)
        namespace << id
      end

      namespace.join("/")
    end

    # Tries to place side loads onto given resources.
    def side_load(resources, side_loads)
      key = "#{options.name}_id"
      plural_key = "#{Inflection.singular options.name.to_s}_ids"

      resources.each do |resource|
        if resource.key?(plural_key) # Grab associations from child_ids field on resource
          side_load_from_child_ids(resource, side_loads, plural_key)
        elsif resource.key?(key) || options.singular
          side_load_from_child_or_parent_id(resource, side_loads, key)
        else # Grab associations from parent_id field from multiple child resources
          side_load_from_parent_id(resource, side_loads, key)
        end
      end
    end

    private

    # @return [Array<String>] ['ZendeskAPI', 'Voice', etc.. ]
    def ignorable_namespace_strings
      ZendeskAPI::DataNamespace.descendants.map { |klass| klass.to_s.split('::') }.flatten.uniq
    end

    def _side_load(resource, side_loads)
      side_loads.map! do |side_load|
        resource.send(:wrap_resource, side_load, options)
      end

      ZendeskAPI::Collection.new(resource.client, options[:class]).tap do |collection|
        collection.replace(side_loads)
      end
    end

    def side_load_from_parent_id(resource, side_loads, key)
      key = "#{resource.class.singular_resource_name}_id"

      resource.send("#{options.name}=", _side_load(resource, side_loads.select {|side_load|
        side_load[key] == resource.id
      }))
    end

    def side_load_from_child_ids(resource, side_loads, plural_key)
      ids = resource.send(plural_key)

      resource.send("#{options.name}=", _side_load(resource, side_loads.select {|side_load|
        ids.include?(side_load[options.include_key])
      }))
    end

    def side_load_from_child_or_parent_id(resource, side_loads, key)
      # Either grab association from child_id field on resource or parent_id on child resource
      if resource.key?(key)
        id = resource.send(key)
        include_key = options.include_key
      else
        id = resource.id
        include_key = "#{resource.class.singular_resource_name}_id"
      end

      return unless id

      side_load = side_loads.detect do |side_load|
        id == side_load[include_key]
      end

      resource.send("#{options.name}=", side_load) if side_load
    end

    def build_parent_namespace(parent_class, instance, options, original_options)
      path = @options.path

      association_on_parent = parent_class.associations.detect { |a| a[:name] == @options[:name] }
      association_on_parent ||= parent_class.associations.detect do |a|
        !a[:inline] && a[:class] == @options[:class]
      end

      if association_on_parent
        path ||= association_on_parent[:path]
        path ||= association_on_parent[:name].to_s
      end

      path ||= @options[:class].resource_path

      [
        extract_parent_id(parent_class, instance, options, original_options),
        path
      ]
    end

    def extract_parent_id(parent_class, instance, options, original_options)
      parent_id_column = "#{parent_class.singular_resource_name}_id"

      if @options.parent
        @options.parent.id
      elsif instance
        instance.send(parent_id_column)
      elsif options[parent_id_column]
        original_options.delete(parent_id_column) || original_options.delete(parent_id_column.to_sym)
      else
        raise ArgumentError.new("#{@options[:class].resource_name} requires #{parent_id_column} or parent")
      end
    end

    def extract_id(instance, options, original_options)
      if options[:with_id] && !@options[:class].ancestors.include?(SingularResource)
        if instance && instance.id
          instance.id
        elsif options[:id]
          original_options.delete(:id) || original_options.delete("id")
        end
      end
    end
  end
end

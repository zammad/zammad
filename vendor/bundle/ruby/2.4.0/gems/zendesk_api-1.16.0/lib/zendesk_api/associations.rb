require 'zendesk_api/helpers'

module ZendeskAPI
  # This module holds association method for resources.
  # Associations can be loaded in three ways:
  # * Commonly used resources are automatically side-loaded server side and sent along with their parent object.
  # * Associated resource ids are sent and are then loaded one-by-one into the parent collection.
  # * The association is represented with Rails' nested association urls (such as tickets/:id/groups) and are loaded that way.
  #
  # @private
  module Associations
    def self.included(base)
      base.extend ClassMethods
    end

    def wrap_resource(resource, class_level_association, options = {})
      instance_association = Association.new(class_level_association.merge(:parent => self))
      klass = class_level_association[:class]

      case resource
      when Hash
        klass.new(@client, resource.merge(:association => instance_association))
      when String, Integer
        klass.new(@client, (options[:include_key] || :id) => resource, :association => instance_association)
      else
        resource.association = instance_association
        resource
      end
    end

    # @private
    module ClassMethods
      def self.extended(klass)
        klass.extend Has
        klass.extend HasMany
      end

      def associations
        @associations ||= []
      end

      def associated_with(name)
        associations.inject([]) do |associated_with, association|
          if association[:include] == name.to_s
            associated_with.push(Association.new(association))
          end

          associated_with
        end
      end

      private

      def build_association(klass, resource_name, options)
        {
          :class => klass,
          :name => resource_name,
          :inline => options.delete(:inline),
          :path => options.delete(:path),
          :include => (options.delete(:include) || klass.resource_name).to_s,
          :include_key => (options.delete(:include_key) || :id).to_s,
          :singular => options.delete(:singular),
          :extensions => Array(options.delete(:extend))
        }
      end

      def define_used(association)
        define_method "#{association[:name]}_used?" do
          !!instance_variable_get("@#{association[:name]}")
        end
      end

      module Has
        # Represents a parent-to-child association between resources. Options to pass in are: class, path.
        # @param [Symbol] resource_name_or_class The underlying resource name or a class to get it from
        # @param [Hash] class_level_options The options to pass to the method definition.
        def has(resource_name_or_class, class_level_options = {})
          if klass = class_level_options.delete(:class)
            resource_name = resource_name_or_class
          else
            klass = resource_name_or_class
            resource_name = klass.singular_resource_name
          end

          class_level_association = build_association(klass, resource_name, class_level_options)
          class_level_association.merge!(:singular => true, :id_column => "#{resource_name}_id")

          associations << class_level_association

          define_used(class_level_association)
          define_has_getter(class_level_association)
          define_has_setter(class_level_association)
        end

        private

        def define_has_getter(association)
          klass = association[:class] # shorthand

          define_method association[:name] do |*args|
            instance_options = args.last.is_a?(Hash) ? args.pop : {}

            # return if cached
            cached = instance_variable_get("@#{association[:name]}")
            return cached if cached && !instance_options[:reload]

            # find and cache association
            instance_association = Association.new(association.merge(:parent => self))
            resource = if klass.respond_to?(:find) && resource_id = method_missing(association[:id_column])
              klass.find(@client, :id => resource_id, :association => instance_association)
            elsif found = method_missing(association[:name].to_sym)
              wrap_resource(found, association, :include_key => association[:include_key])
            elsif klass.superclass == DataResource && !association[:inline]
              response = @client.connection.get(instance_association.generate_path(:with_parent => true))
              klass.new(@client, response.body[klass.singular_resource_name].merge(:association => instance_association))
            end

            send("#{association[:id_column]}=", resource.id) if resource && has_key?(association[:id_column])
            instance_variable_set("@#{association[:name]}", resource)
          end
        end

        def define_has_setter(association)
          define_method "#{association[:name]}=" do |resource|
            resource = wrap_resource(resource, association)
            send("#{association[:id_column]}=", resource.id) if has_key?(association[:id_column])
            instance_variable_set("@#{association[:name]}", resource)
          end
        end
      end

      module HasMany
        # Represents a parent-to-children association between resources. Options to pass in are: class, path.
        # @param [Symbol] resource_name_or_class The underlying resource name or class to get it from
        # @param [Hash] class_level_options The options to pass to the method definition.
        def has_many(resource_name_or_class, class_level_options = {})
          if klass = class_level_options.delete(:class)
            resource_name = resource_name_or_class
          else
            klass = resource_name_or_class
            resource_name = klass.resource_name
          end

          class_level_association = build_association(klass, resource_name, class_level_options)
          class_level_association.merge!(:singular => false, :id_column => "#{resource_name}_ids")

          associations << class_level_association

          define_used(class_level_association)
          define_has_many_getter(class_level_association)
          define_has_many_setter(class_level_association)
        end

        private

        def define_has_many_getter(association)
          klass = association[:class]

          define_method association[:name] do |*args|
            instance_opts = args.last.is_a?(Hash) ? args.pop : {}

            # return if cached
            cached = instance_variable_get("@#{association[:name]}")
            return cached if cached && !instance_opts[:reload]

            # find and cache association
            instance_association = Association.new(association.merge(:parent => self))
            singular_resource_name = Inflection.singular(association[:name].to_s)

            resources = if (ids = method_missing("#{singular_resource_name}_ids")) && ids.any?
              ids.map do |id|
                klass.find(@client, :id => id, :association => instance_association)
              end.compact
            elsif (resources = method_missing(association[:name].to_sym)) && resources.any?
              resources.map { |res| wrap_resource(res, association) }
            else
              []
            end

            collection = ZendeskAPI::Collection.new(@client, klass, instance_opts.merge(:association => instance_association))

            if association[:extensions].any?
              collection.extend(*association[:extensions])
            end

            if resources.any?
              collection.replace(resources)
            end

            send("#{association[:id_column]}=", resources.map(&:id)) if has_key?(association[:id_column])
            instance_variable_set("@#{association[:name]}", collection)
          end
        end

        def define_has_many_setter(association)
          define_method "#{association[:name]}=" do |resources|
            if resources.is_a?(Array)
              wrapped = resources.map { |attr| wrap_resource(attr, association) }
              send(association[:name]).replace(wrapped)
            else
              resources.association = Association.new(association.merge(:parent => self))
              instance_variable_set("@#{association[:name]}", resources)
            end

            send("#{association[:id_column]}=", resources.map(&:id)) if resources && has_key?(association[:id_column])
            resource
          end
        end
      end
    end
  end
end

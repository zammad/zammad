module ZendeskAPI
  module ResponseHandler
    def handle_response(response)
      if response.body.is_a?(Hash) && response.body[self.class.singular_resource_name]
        @attributes.replace(@attributes.deep_merge(response.body[self.class.singular_resource_name]))
      end
    end
  end

  module Save
    include ResponseHandler

    # If this resource hasn't been deleted, then create or save it.
    # Executes a POST if it is a {Data#new_record?}, otherwise a PUT.
    # Merges returned attributes on success.
    # @return [Boolean] Success?
    def save!(options = {})
      return false if respond_to?(:destroyed?) && destroyed?

      if new_record? && !options[:force_update]
        method = :post
        req_path = path
      else
        method = :put
        req_path = url || path
      end

      req_path = options[:path] if options[:path]

      save_associations

      @response = @client.connection.send(method, req_path) do |req|
        req.body = attributes_for_save.merge(@global_params)

        yield req if block_given?
      end

      handle_response(@response)

      @attributes.clear_changes
      clear_associations
      true
    end

    # Saves, returning false if it fails and attaching the errors
    def save(options = {}, &block)
      save!(options, &block)
    rescue ZendeskAPI::Error::RecordInvalid => e
      @errors = e.errors
      false
    rescue ZendeskAPI::Error::ClientError
      false
    end

    # Removes all cached associations
    def clear_associations
      self.class.associations.each do |association_data|
        name = association_data[:name]
        instance_variable_set("@#{name}", nil) if instance_variable_defined?("@#{name}")
      end
    end

    # Saves associations
    # Takes into account inlining, collections, and id setting on the parent resource.
    def save_associations
      self.class.associations.each do |association_data|
        association_name = association_data[:name]

        next unless send("#{association_name}_used?") && association = send(association_name)

        inline_creation = association_data[:inline] == :create && new_record?
        changed = association.is_a?(Collection) || association.changed?

        if association.respond_to?(:save) && changed && !inline_creation && association.save
          send("#{association_name}=", association) # set id/ids columns
        end

        if (association_data[:inline] == true || inline_creation) && changed
          attributes[association_name] = association.to_param
        end
      end
    end
  end

  module Read
    include ResponseHandler
    include ZendeskAPI::Sideloading

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Reloads a resource.
    def reload!
      response = @client.connection.get(path) do |req|
        yield req if block_given?
      end

      handle_response(response)
      attributes.clear_changes
      self
    end

    module ClassMethods
      # Finds a resource by an id and any options passed in.
      # A custom path to search at can be passed into opts. It defaults to the {Data.resource_name} of the class.
      # @param [Client] client The {Client} object to be used
      # @param [Hash] options Any additional GET parameters to be added
      def find!(client, options = {})
        @client = client # so we can use client.logger in rescue

        raise ArgumentError, "No :id given" unless options[:id] || options["id"] || ancestors.include?(SingularResource)
        association = options.delete(:association) || Association.new(:class => self)

        includes = Array(options[:include])
        options[:include] = includes.join(",") if includes.any?

        response = client.connection.get(association.generate_path(options)) do |req|
          req.params = options

          yield req if block_given?
        end

        new_from_response(client, response, includes)
      end

      # Finds, returning nil if it fails
      # @param [Client] client The {Client} object to be used
      # @param [Hash] options Any additional GET parameters to be added
      def find(client, options = {}, &block)
        find!(client, options, &block)
      rescue ZendeskAPI::Error::ClientError
        nil
      end
    end
  end

  module Create
    include Save

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Create a resource given the attributes passed in.
      # @param [Client] client The {Client} object to be used
      # @param [Hash] attributes The attributes to create.
      def create!(client, attributes = {}, &block)
        ZendeskAPI::Client.check_deprecated_namespace_usage attributes, singular_resource_name

        new(client, attributes).tap do |resource|
          resource.save!(&block)
        end
      end

      # Creates, returning nil if it fails
      # @param [Client] client The {Client} object to be used
      # @param [Hash] options Any additional GET parameters to be added
      def create(client, attributes = {}, &block)
        create!(client, attributes, &block)
      rescue ZendeskAPI::Error::ClientError
        nil
      end
    end
  end

  module CreateMany
    # Creates multiple resources using the create_many endpoint.
    # @param [Client] client The {Client} object to be used
    # @param [Array] attributes_array An array of resources to be created.
    # @return [JobStatus] the {JobStatus} instance for this create job
    def create_many!(client, attributes_array, association = Association.new(:class => self))
      response = client.connection.post("#{association.generate_path}/create_many") do |req|
        req.body = { resource_name => attributes_array }

        yield req if block_given?
      end

      JobStatus.new_from_response(client, response)
    end
  end

  module Destroy
    def self.included(klass)
      klass.extend(ClassMethod)
    end

    # Has this object been deleted?
    def destroyed?
      @destroyed ||= false
    end

    # If this resource hasn't already been deleted, then do so.
    # @return [Boolean] Successful?
    def destroy!
      return false if destroyed? || new_record?

      @client.connection.delete(url || path) do |req|
        yield req if block_given?
      end

      @destroyed = true
    end

    # Destroys, returning false on error.
    def destroy(&block)
      destroy!(&block)
    rescue ZendeskAPI::Error::ClientError
      false
    end

    module ClassMethod
      # Deletes a resource given the id passed in.
      # @param [Client] client The {Client} object to be used
      # @param [Hash] opts The optional parameters to pass. Defaults to {}
      def destroy!(client, opts = {}, &block)
        new(client, opts).destroy!(&block)

        true
      end

      # Destroys, returning false on error.
      def destroy(client, attributes = {}, &block)
        destroy!(client, attributes, &block)
      rescue ZendeskAPI::Error::ClientError
        false
      end
    end
  end

  module DestroyMany
    # Destroys multiple resources using the destroy_many endpoint.
    # @param [Client] client The {Client} object to be used
    # @param [Array] ids An array of ids to destroy
    # @return [JobStatus] the {JobStatus} instance for this destroy job
    def destroy_many!(client, ids, association = Association.new(:class => self))
      response = client.connection.delete("#{association.generate_path}/destroy_many") do |req|
        req.params = { :ids => ids.join(',') }

        yield req if block_given?
      end

      JobStatus.new_from_response(client, response)
    end
  end

  module Update
    include Save

    def self.included(klass)
      klass.extend(ClassMethod)
    end

    module ClassMethod
      # Updates, returning false on error.
      def update(client, attributes = {}, &block)
        update!(client, attributes, &block)
      rescue ZendeskAPI::Error::ClientError
        false
      end

      # Updates a resource given the id passed in.
      # @param [Client] client The {Client} object to be used
      # @param [Hash] attributes The attributes to update. Default to {
      def update!(client, attributes = {}, &block)
        ZendeskAPI::Client.check_deprecated_namespace_usage attributes, singular_resource_name
        resource = new(client, :id => attributes.delete(:id), :global => attributes.delete(:global), :association => attributes.delete(:association))
        resource.attributes.merge!(attributes)
        resource.save!(:force_update => resource.is_a?(SingularResource), &block)
        resource
      end
    end
  end

  module UpdateMany
    # Updates multiple resources using the update_many endpoint.
    # @param [Client] client The {Client} object to be used
    # @param [Array] ids_or_attributes An array of ids or arributes including ids to update
    # @param [Hash] attributes The attributes to update resources with
    # @return [JobStatus] the {JobStatus} instance for this destroy job
    def update_many!(client, ids_or_attributes, attributes = {})
      association = attributes.delete(:association) || Association.new(:class => self)

      response = client.connection.put("#{association.generate_path}/update_many") do |req|
        if attributes == {}
          req.body = { resource_name => ids_or_attributes }
        else
          req.params = { :ids => ids_or_attributes.join(',') }
          req.body = { singular_resource_name => attributes }
        end

        yield req if block_given?
      end

      JobStatus.new_from_response(client, response)
    end
  end
end

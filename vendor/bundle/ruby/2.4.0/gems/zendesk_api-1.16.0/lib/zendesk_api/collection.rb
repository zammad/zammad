require 'zendesk_api/resource'
require 'zendesk_api/resources'

module ZendeskAPI
  # Represents a collection of resources. Lazily loaded, resources aren't
  # actually fetched until explicitly needed (e.g. #each, {#fetch}).
  class Collection
    include ZendeskAPI::Sideloading

    # Options passed in that are automatically converted from an array to a comma-separated list.
    SPECIALLY_JOINED_PARAMS = [:ids, :only]

    # @return [ZendeskAPI::Association] The class association
    attr_reader :association

    # @return [Faraday::Response] The last response
    attr_reader :response

    # @return [Hash] query options
    attr_reader :options

    # @return [ZendeskAPI::ClientError] The last response error
    attr_reader :error

    # Creates a new Collection instance. Does not fetch resources.
    # Additional options are: verb (default: GET), path (default: resource param), page, per_page.
    # @param [Client] client The {Client} to use.
    # @param [String] resource The resource being collected.
    # @param [Hash] options Any additional options to be passed in.
    def initialize(client, resource, options = {})
      @client, @resource_class, @resource = client, resource, resource.resource_name
      @options = SilentMash.new(options)

      set_association_from_options
      join_special_params

      @verb = @options.delete(:verb)
      @includes = Array(@options.delete(:include))

      # Used for Attachments, TicketComment
      if @resource_class.is_a?(Class) && @resource_class.superclass == ZendeskAPI::Data
        @resources = []
        @fetchable = false
      else
        @fetchable = true
      end
    end

    # Methods that take a Hash argument
    methods = %w{create find update update_many destroy}
    methods += methods.map { |method| method + "!" }
    methods.each do |deferrable|
      # Passes arguments and the proper path to the resource class method.
      # @param [Hash] options Options or attributes to pass
      define_method deferrable do |*args|
        unless @resource_class.respond_to?(deferrable)
          raise NoMethodError.new("undefined method \"#{deferrable}\" for #{@resource_class}", deferrable, args)
        end

        args << {} unless args.last.is_a?(Hash)
        args.last.merge!(:association => @association)

        @resource_class.send(deferrable, @client, *args)
      end
    end

    # Methods that take an Array argument
    methods = %w{create_many! destroy_many!}
    methods.each do |deferrable|
      # Passes arguments and the proper path to the resource class method.
      # @param [Array] array arguments
      define_method deferrable do |*args|
        unless @resource_class.respond_to?(deferrable)
          raise NoMethodError.new("undefined method \"#{deferrable}\" for #{@resource_class}", deferrable, args)
        end

        array = args.last.is_a?(Array) ? args.pop : []

        @resource_class.send(deferrable, @client, array, @association)
      end
    end

    # Convenience method to build a new resource and
    # add it to the collection. Fetches the collection as well.
    # @param [Hash] opts Options or attributes to pass
    def build(opts = {})
      wrap_resource(opts, true).tap do |res|
        self << res
      end
    end

    # Convenience method to build a new resource and
    # add it to the collection. Fetches the collection as well.
    # @param [Hash] opts Options or attributes to pass
    def build!(opts = {})
      wrap_resource(opts, true).tap do |res|
        fetch!

        # << does a fetch too
        self << res
      end
    end

    # @return [Number] The total number of resources server-side (disregarding pagination).
    def count
      fetch
      @count || -1
    end

    # @return [Number] The total number of resources server-side (disregarding pagination).
    def count!
      fetch!
      @count || -1
    end

    # Changes the per_page option. Returns self, so it can be chained. No execution.
    # @return [Collection] self
    def per_page(count)
      clear_cache if count
      @options["per_page"] = count
      self
    end

    # Changes the page option. Returns self, so it can be chained. No execution.
    # @return [Collection] self
    def page(number)
      clear_cache if number
      @options["page"] = number
      self
    end

    def first_page?
      !@prev_page
    end

    def last_page?
      !@next_page || @next_page == @query
    end

    # Saves all newly created resources stored in this collection.
    # @return [Collection] self
    def save
      _save
    end

    # Saves all newly created resources stored in this collection.
    # @return [Collection] self
    def save!
      _save(:save!)
    end

    # Adds an item (or items) to the list of side-loaded resources to request
    # @option sideloads [Symbol or String] The item(s) to sideload
    def include(*sideloads)
      tap { @includes.concat(sideloads.map(&:to_s)) }
    end

    # Adds an item to this collection
    # @option item [ZendeskAPI::Data] the resource to add
    # @raise [ArgumentError] if the resource doesn't belong in this collection
    def <<(item)
      fetch

      if item.is_a?(Resource)
        if item.is_a?(@resource_class)
          @resources << item
        else
          raise "this collection is for #{@resource_class}"
        end
      else
        @resources << wrap_resource(item, true)
      end
    end

    # The API path to this collection
    def path
      @association.generate_path(:with_parent => true)
    end

    # Executes actual GET from API and loads resources into proper class.
    # @param [Boolean] reload Whether to disregard cache
    def fetch!(reload = false)
      if @resources && (!@fetchable || !reload)
        return @resources
      elsif association && association.options.parent && association.options.parent.new_record?
        return (@resources = [])
      end

      @response = get_response(@query || path)
      handle_response(@response.body)

      @resources
    end

    def fetch(*args)
      fetch!(*args)
    rescue Faraday::Error::ClientError => e
      @error = e

      []
    end

    # Alias for fetch(false)
    def to_a
      fetch
    end

    # Alias for fetch!(false)
    def to_a!
      fetch!
    end

    # Calls #each on every page with the passed in block
    # @param [Block] block Passed to #each
    def all!(start_page = @options["page"], &block)
      _all(start_page, :bang, &block)
    end

    # Calls #each on every page with the passed in block
    # @param [Block] block Passed to #each
    def all(start_page = @options["page"], &block)
      _all(start_page, &block)
    end

    def each_page!(*args, &block)
      warn "ZendeskAPI::Collection#each_page! is deprecated, please use ZendeskAPI::Collection#all!"
      all!(*args, &block)
    end

    def each_page(*args, &block)
      warn "ZendeskAPI::Collection#each_page is deprecated, please use ZendeskAPI::Collection#all"
      all(*args, &block)
    end

    # Replaces the current (loaded or not) resources with the passed in collection
    # @option collection [Array] The collection to replace this one with
    # @raise [ArgumentError] if any resources passed in don't belong in this collection
    def replace(collection)
      raise "this collection is for #{@resource_class}" if collection.any? { |r| !r.is_a?(@resource_class) }
      @resources = collection
    end

    # Find the next page. Does one of three things:
    # * If there is already a page number in the options hash, it increases it and invalidates the cache, returning the new page number.
    # * If there is a next_page url cached, it executes a fetch on that url and returns the results.
    # * Otherwise, returns an empty array.
    def next
      if @options["page"]
        clear_cache
        @options["page"] += 1
      elsif @query = @next_page
        fetch(true)
      else
        clear_cache
        @resources = []
      end
    end

    # Find the previous page. Does one of three things:
    # * If there is already a page number in the options hash, it increases it and invalidates the cache, returning the new page number.
    # * If there is a prev_page url cached, it executes a fetch on that url and returns the results.
    # * Otherwise, returns an empty array.
    def prev
      if @options["page"] && @options["page"] > 1
        clear_cache
        @options["page"] -= 1
      elsif @query = @prev_page
        fetch(true)
      else
        clear_cache
        @resources = []
      end
    end

    # Clears all cached resources and associated values.
    def clear_cache
      @resources = nil
      @count = nil
      @next_page = nil
      @prev_page = nil
      @query = nil
    end

    # @private
    def to_ary
      nil
    end

    def respond_to_missing?(name, include_all)
      [].respond_to?(name, include_all)
    end

    # Sends methods to underlying array of resources.
    def method_missing(name, *args, &block)
      if resource_methods.include?(name)
        collection_method(name, *args, &block)
      elsif [].respond_to?(name, false)
        array_method(name, *args, &block)
      else
        next_collection(name, *args, &block)
      end
    end

    # @private
    def to_s
      if @resources
        @resources.inspect
      else
        inspect = []
        inspect << "options=#{@options.inspect}" if @options.any?
        inspect << "path=#{path}"
        "#{Inflection.singular(@resource)} collection [#{inspect.join(',')}]"
      end
    end

    alias :to_str :to_s

    def to_param
      map(&:to_param)
    end

    private

    def set_page_and_count(body)
      @count = (body["count"] || @resources.size).to_i
      @next_page, @prev_page = body["next_page"], body["previous_page"]

      if @next_page =~ /page=(\d+)/
        @options["page"] = $1.to_i - 1
      elsif @prev_page =~ /page=(\d+)/
        @options["page"] = $1.to_i + 1
      end
    end

    def _all(start_page = @options["page"], bang = false, &block)
      raise(ArgumentError, "must pass a block") unless block

      page(start_page)
      clear_cache

      while (bang ? fetch! : fetch)
        each do |resource|
          arguments = [resource, @options["page"] || 1]

          if block.arity >= 0
            arguments = arguments.take(block.arity)
          end

          block.call(*arguments)
        end

        last_page? ? break : self.next
      end

      page(nil)
      clear_cache
    end

    def _save(method = :save)
      return self unless @resources

      result = true

      @resources.map! do |item|
        if item.respond_to?(method) && !item.destroyed? && item.changed?
          result &&= item.send(method)
        end

        item
      end

      result
    end

    ## Initialize

    def join_special_params
      # some params use comma-joined strings instead of query-based arrays for multiple values
      @options.each do |k, v|
        if SPECIALLY_JOINED_PARAMS.include?(k.to_sym) && v.is_a?(Array)
          @options[k] = v.join(',')
        end
      end
    end

    def set_association_from_options
      @collection_path = @options.delete(:collection_path)

      association_options = { :path => @options.delete(:path) }
      association_options[:path] ||= @collection_path.join("/") if @collection_path
      @association = @options.delete(:association) || Association.new(association_options.merge(:class => @resource_class))

      @collection_path ||= [@resource]
    end

    ## Fetch

    def get_response(path)
      @error = nil
      @response = @client.connection.send(@verb || "get", path) do |req|
        opts = @options.delete_if { |_, v| v.nil? }

        req.params.merge!(:include => @includes.join(",")) if @includes.any?

        if %w{put post}.include?(@verb.to_s)
          req.body = opts
        else
          req.params.merge!(opts)
        end
      end
    end

    def handle_response(response_body)
      unless response_body.is_a?(Hash)
        raise ZendeskAPI::Error::NetworkError, @response.env
      end

      body = response_body.dup
      results = body.delete(@resource_class.model_key) || body.delete("results")

      unless results
        raise ZendeskAPI::Error::ClientError, "Expected #{@resource_class.model_key} or 'results' in response keys: #{body.keys.inspect}"
      end

      @resources = results.map do |res|
        wrap_resource(res)
      end

      set_page_and_count(body)
      set_includes(@resources, @includes, body)
    end

    # Simplified Associations#wrap_resource
    def wrap_resource(res, with_association = with_association?)
      case res
      when Array
        wrap_resource(Hash[*res], with_association)
      when Hash
        res = res.merge(:association => @association) if with_association
        @resource_class.new(@client, res)
      else
        res = { :id => res }
        res.merge!(:association => @association) if with_association
        @resource_class.new(@client, res)
      end
    end

    # Two special cases, and all namespaced classes
    def with_association?
      [Tag, Setting].include?(@resource_class) ||
        @resource_class.to_s.split("::").size > 2
    end

    ## Method missing

    def array_method(name, *args, &block)
      to_a.public_send(name, *args, &block)
    end

    def next_collection(name, *args, &block)
      opts = args.last.is_a?(Hash) ? args.last : {}
      opts.merge!(:collection_path => @collection_path.dup.push(name))
      self.class.new(@client, @resource_class, @options.merge(opts))
    end

    def collection_method(name, *args, &block)
      @resource_class.send(name, @client, *args, &block)
    end

    def resource_methods
      @resource_methods ||= @resource_class.singleton_methods(false).map(&:to_sym)
    end
  end
end

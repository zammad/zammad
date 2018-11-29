module ZendeskAPI
  # @private
  module Sideloading
    def self.included(klass)
      klass.send(:attr_reader, :included)
    end

    def set_includes(resource_or_resources, includes, body)
      @included = {}

      includes.each do |side_load|
        unless body.key?(side_load.to_s)
          @client.config.logger.warn "Missing #{side_load} key in response -- cannot side load"
        end
      end

      resources = to_array(resource_or_resources)
      resource_class = resources.first.class

      return if resources.empty?

      body.keys.each do |name|
        @included[name] = body[name]
        _side_load(name, resource_class, resources)
      end
    end

    private

    # Traverses the resource looking for associations
    # then descends into those associations and checks for applicable
    # resources to side load
    def _side_load(name, klass, resources)
      associations = klass.associated_with(name)

      associations.each do |association|
        association.side_load(resources, @included[name])
      end

      resources.each do |resource|
        loaded_associations = resource.loaded_associations
        loaded_associations.each do |association|
          loaded = resource.send(association[:name])
          next unless loaded
          _side_load(name, association[:class], to_array(loaded))
        end
      end
    end

    def to_array(item)
      if item.is_a?(Collection)
        item
      else
        [item].flatten.compact
      end
    end
  end
end

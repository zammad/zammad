module Import
  class BaseResource
    include Import::Helper

    def initialize(resource)
      import(resource)
    end

    def import_class
      raise "#{self.class.name} has no implmentation of the needed 'import_class' method"
    end

    def source
      raise "#{self.class.name} has no implmentation of the needed 'source' method"
    end

    def remote_id(resource)
      @remote_id ||= resource.delete(:id)
    end

    private

    def import(resource)
      create_or_update(map(resource))
    end

    def create_or_update(resource)
      return if updated?(resource)
      create(resource)
    end

    def updated?(resource)
      @resource = lookup_existing(resource)
      return false if !@resource
      @resource.update_attributes(resource)
      post_update(
        instance:   @resource,
        attributes: resource
      )
      true
    end

    def lookup_existing(resource)

      instance = ExternalSync.find_by(
        source:    source,
        source_id: remote_id(resource),
        object:    import_class.name,
      )
      return if !instance
      import_class.find_by(id: instance.o_id)
    end

    def create(resource)
      @resource = import_class.new(resource)
      @resource.save

      ExternalSync.create(
        source:    source,
        source_id: remote_id(resource),
        object:    import_class.name,
        o_id:      @resource.id
      )

      post_create(
        instance:   @resource,
        attributes: resource
      )
    end

    def defaults(_resource)
      {
        created_by_id: 1,
        updated_by_id: 1,
      }
    end

    def map(resource)
      mapped     = from_mapping(resource)
      attributes = defaults(resource).merge(mapped)
      attributes.symbolize_keys
    end

    def from_mapping(resource)
      return resource if !mapping

      ExternalSync.map(
        mapping: mapping,
        source:  resource
      )
    end

    def mapping
      Setting.get(mapping_config)
    end

    def mapping_config
      self.class.name.to_s.sub('Import::', '').gsub('::', '_').underscore + '_mapping'
    end

    def post_create(_args)
    end

    def post_update(_args)
    end
  end
end

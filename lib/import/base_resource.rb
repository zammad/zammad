module Import
  class BaseResource
    include Import::Helper

    def initialize(resource, *args)
      import(resource, *args)
    end

    def import_class
      raise "#{self.class.name} has no implmentation of the needed 'import_class' method"
    end

    def source
      raise "#{self.class.name} has no implmentation of the needed 'source' method"
    end

    def remote_id(resource, *_args)
      @remote_id ||= resource.delete(:id)
    end

    private

    def import(resource, *args)
      create_or_update(map(resource, *args), *args)
    end

    def create_or_update(resource, *args)
      return if updated?(resource, *args)
      create(resource, *args)
    end

    def updated?(resource, *args)
      @resource = lookup_existing(resource, *args)
      return false if !@resource
      @resource.update_attributes(resource)
      post_update(
        instance:   @resource,
        attributes: resource
      )
      true
    end

    def lookup_existing(resource, *_args)

      instance = ExternalSync.find_by(
        source:    source,
        source_id: remote_id(resource),
        object:    import_class.name,
      )
      return if !instance
      import_class.find_by(id: instance.o_id)
    end

    def create(resource, *_args)
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

    def defaults(_resource, *_args)
      {
        created_by_id: 1,
        updated_by_id: 1,
      }
    end

    def map(resource, *args)
      mapped     = from_mapping(resource, *args)
      attributes = defaults(resource, *args).merge(mapped)
      attributes.symbolize_keys
    end

    def from_mapping(resource, *args)
      return resource if !mapping(*args)

      ExternalSync.map(
        mapping: mapping,
        source:  resource
      )
    end

    def mapping(*args)
      Setting.get(mapping_config(*args))
    end

    def mapping_config(*_args)
      self.class.name.to_s.sub('Import::', '').gsub('::', '_').underscore + '_mapping'
    end

    def post_create(_args)
    end

    def post_update(_args)
    end
  end
end

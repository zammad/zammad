module Import
  class BaseResource
    include Import::Helper

    attr_reader :resource, :remote_id, :errors

    def initialize(resource, *args)
      handle_args(resource, *args)
      import(resource, *args)
    end

    def import_class
      raise NoMethodError, "#{self.class.name} has no implementation of the needed 'import_class' method"
    end

    def source
      import_class_namespace
    end

    def remote_id(resource, *_args)
      @remote_id ||= resource.delete(:id)
    end

    def action
      return :failed if errors.present?
      return :skipped if !@resource
      return :unchanged if !attributes_changed?
      return :created if created?
      :updated
    end

    def attributes_changed?
      return true if changed_attributes.present?
      @associations_init != associations_state(@resource)
    end

    def changed_attributes
      return if @resource.blank?
      # dry run
      return @resource.changes if @resource.changed?
      # live run
      @resource.previous_changes
    end

    def created?
      return false if @resource.blank?
      # dry run
      return @resource.created_at.nil? if @resource.changed?
      # live run
      @resource.created_at == @resource.updated_at
    end

    private

    def import(resource, *args)
      create_or_update(map(resource, *args), *args)
    rescue => e
      # Don't catch own thrown exceptions from above
      raise if e.is_a?(NoMethodError)
      handle_error(e)
    end

    def create_or_update(resource, *args)
      return if updated?(resource, *args)
      create(resource, *args)
    end

    def updated?(resource, *args)
      @resource = lookup_existing(resource, *args)
      return false if !@resource

      # delete since we have an update and
      # the record is already created
      resource.delete(:created_by_id)

      @resource.assign_attributes(resource)

      # the return value here is kind of misleading
      # and should not be trusted to indicate if a
      # resource was actually updated.
      # Use .action instead
      return true if !attributes_changed?

      return true if @dry_run
      @resource.save
      true
    end

    def lookup_existing(resource, *_args)

      synced_instance = ExternalSync.find_by(
        source:    source,
        source_id: remote_id(resource),
        object:    import_class.name,
      )
      return if !synced_instance
      instance = import_class.find_by(id: synced_instance.o_id)

      store_associations_state(instance)

      instance
    end

    def store_associations_state(instance)
      @associations_init = associations_state(instance)
    end

    def associations_state(instance)
      state = {}
      tracked_associations.each do |association|
        state[association] = instance.send(association)
      end
      state
    end

    def tracked_associations
      # loop over all reflections
      import_class.reflect_on_all_associations.collect do |reflection|
        # refection name is something like groups or organization (singular/plural)
        reflection_name = reflection.name.to_s
        # key is something like group_id or organization_id (singular)
        key = reflection.klass.name.foreign_key

        # add trailing 's' to get pluralized key
        if reflection_name.singularize != reflection_name
          key = "#{key}s"
        end

        key.to_sym
      end
    end

    def create(resource, *_args)
      @resource = import_class.new(resource)
      return if @dry_run
      @resource.save
      external_sync_create(
        local:  @resource,
        remote: resource,
      )
    end

    def external_sync_create(local:, remote:)
      ExternalSync.create(
        source:    source,
        source_id: remote_id(remote),
        object:    import_class.name,
        o_id:      local.id
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
      mapping = mapping(*args)
      return resource if !mapping

      ExternalSync.map(
        mapping: mapping,
        source:  resource
      )
    end

    def mapping(*args)
      Setting.get(mapping_config(*args))
    end

    def mapping_config(*_args)
      import_class_namespace.gsub('::', '_').underscore + '_mapping'
    end

    def import_class_namespace
      self.class.name.to_s.sub('Import::', '')
    end

    def handle_args(_resource, *args)
      return if !args
      return if !args.is_a?(Array)
      return if args.empty?

      last_arg = args.last
      return if !last_arg.is_a?(Hash)
      handle_modifiers(last_arg)
    end

    def handle_modifiers(modifiers)
      @dry_run = modifiers.fetch(:dry_run, false)
    end

    def handle_error(e)
      @errors ||= []
      @errors.push(e)
      Rails.logger.error e
    end
  end
end

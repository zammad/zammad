module Import
  class BaseResource
    include Import::Helper

    attr_reader :resource, :remote_id, :errors

    def initialize(resource, *args)
      @action = :unknown
      handle_args(resource, *args)
      initialize_associations_states
      import(resource, *args)
    end

    def import_class
      raise NoMethodError, "#{self.class.name} has no implementation of the needed 'import_class' method"
    end

    def source
      self.class.source
    end

    def remote_id(resource, *_args)
      @remote_id ||= resource.delete(:id)
    end

    def action
      return :failed if errors.present?
      return :skipped if @resource.blank?
      return :unchanged if !attributes_changed?
      @action
    end

    def attributes_changed?
      changed_attributes.present? || changed_associations.present?
    end

    def changed_attributes
      return if @resource.blank?
      # dry run
      return @resource.changes if @resource.changed?
      # live run
      @resource.previous_changes
    end

    def changed_associations
      changes = {}
      tracked_associations.each do |association|
        # skip if no new value will get assigned (no change is performed)
        next if !@associations[:after].key?(association)
        # skip if both values are equal
        next if @associations[:before][association] == @associations[:after][association]
        # skip if both values are blank
        next if @associations[:before][association].blank? && @associations[:after][association].blank?
        # store changes
        changes[association] = [@associations[:before][association], @associations[:after][association]]
      end
      changes
    end

    def self.source
      import_class_namespace
    end

    def self.import_class_namespace
      @import_class_namespace ||= name.to_s.sub('Import::', '')
    end

    private

    def initialize_associations_states
      @associations = {}
      %i(before after).each do |state|
        @associations[state] ||= {}
      end
    end

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

      # lock the current resource for write access
      @resource.with_lock do

        # delete since we have an update and
        # the record is already created
        resource.delete(:created_by_id)

        # store the current state of the associations
        # from the resource hash because if we assign
        # them to the instance some (e.g. has_many)
        # will get stored even in the dry run :/
        store_associations(:after, resource)

        associations = tracked_associations
        @resource.assign_attributes(resource.except(*associations))

        # the return value here is kind of misleading
        # and should not be trusted to indicate if a
        # resource was actually updated.
        # Use .action instead
        return true if !attributes_changed?

        @action = :updated

        return true if @dry_run
        @resource.assign_attributes(resource.slice(*associations))
        @resource.save!
        true
      end
    end

    def lookup_existing(resource, *_args)

      synced_instance = ExternalSync.find_by(
        source:    source,
        source_id: remote_id(resource),
        object:    import_class.name,
      )
      return if !synced_instance
      instance = import_class.find_by(id: synced_instance.o_id)

      store_associations(:before, instance)

      instance
    end

    def store_associations(state, source)
      @associations[state] = associations_state(source)
    end

    def associations_state(source)
      state = {}
      tracked_associations.each do |association|
        # we have to support instances and (resource) hashes
        # here since in case of an update we only have the
        # hash as a source but on create we have an instance
        if source.is_a?(Hash)
          # ignore if there is no key for the association
          # of the Hash (update)
          # otherwise wrong changes may get detected
          next if !source.key?(association)
          state[association] = source[association]
        else
          state[association] = source.send(association)
        end
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
      store_associations(:after, @resource)
      @action = :created
      return if @dry_run
      @resource.save!
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
      self.class.import_class_namespace.gsub('::', '_').underscore + '_mapping'
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

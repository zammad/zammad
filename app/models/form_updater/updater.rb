# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater
  include Mixin::RequiredSubPaths

  # Context from GraphQL or possibly other environments.
  # It must respond to :current_user and :current_user? for session information (see Gql::Context::CurrentUserAware).
  # It may respond to :schema with an object providing :id_for_object to perform ID mappings like in Gql::ZammadSchema.
  attr_reader :context, :relation_fields, :meta, :data, :id, :object

  def initialize(context:, relation_fields:, meta:, data:, id: nil)
    @context         = context
    @relation_fields = relation_fields
    @meta            = meta
    @data            = data
    @id              = id
  end

  def object_type
    raise NotImplementedError
  end

  def self.updaters
    descendants
  end

  def self.requires_authentication
    true
  end

  def authorized?
    # The authorized function needs to be implemented for any updaters which have a `id`.
    if id
      @object = Gql::ZammadSchema.authorized_object_from_id id, type: object_type, user: context.current_user
    end

    true
  end

  def resolve
    result = {}

    before_resolve(result)

    if self.class.included_modules.include?(FormUpdater::Concerns::ChecksCoreWorkflow)
      # TODO: ...
    end

    resolve_relation_fields(result)

    result
  end

  private

  # Override this method to implement additional things before default resolve.
  def before_resolve(...)
    true
  end

  def resolve_relation_fields(result)
    relation_fields.each do |relation_field|
      relation_resolver = get_relation_resolver(relation_field)

      result[relation_field[:name]] ||= {}
      result[relation_field[:name]][:options] = relation_resolver.options
    end
  end

  RELATION_CLASS_PREFIX = 'FormUpdater::Relation::'.freeze

  def get_relation_resolver(relation_field)
    relation_class = "#{RELATION_CLASS_PREFIX}#{relation_field[:name].humanize}".safe_constantize
    if !relation_class
      relation_class = "#{RELATION_CLASS_PREFIX}#{relation_field[:relation]}".constantize
    end

    relation_class.new(
      context:    context,
      data:       data,
      filter_ids: relation_field[:filter_ids],
    )
  rescue
    raise "Cannot resolve relation type #{relation_field[:relation]} (#{relation_field[:name]})."
  end
end

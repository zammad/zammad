# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater
  include Mixin::RequiredSubPaths

  # Context from GraphQL or possibly other environments.
  # It must respond to :current_user and :current_user? for session information (see Gql::Context::CurrentUserAware).
  # It may respond to :schema with an object providing :id_for_object to perform ID mappings like in Gql::ZammadSchema.
  attr_reader :context, :current_user, :relation_fields, :meta, :data, :id, :object, :result, :flags

  def initialize(context:, relation_fields:, meta:, data:, id: nil)
    @context         = context
    @meta            = meta
    @data            = data
    @id              = id
    @current_user    = context[:current_user]

    @result = {}
    @flags  = {}

    # Build lookup for relation fields for better usage.
    @relation_fields = relation_fields.to_h do |relation_field|
      [relation_field[:name], relation_field.to_h]
    end
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

  def self.required_permissions
    []
  end

  def authorized?
    if self.class.required_permissions.present? && !current_user.permissions?(self.class.required_permissions)
      return false
    end

    # The authorized function needs to be implemented for any updaters which have a `id`.
    if id
      @object = Gql::ZammadSchema.authorized_object_from_id id, type: object_type, user: current_user
    end

    true
  end

  def resolve
    validate_workflows if self.class.include?(FormUpdater::Concerns::ChecksCoreWorkflow)
    resolve_relation_fields if relation_fields.present?

    handle_updater_flags if self.class.method_defined?(:handle_updater_flags)

    {
      fields: result,
      flags:  flags
    }
  end

  private

  # The object's own value for a form field, and whether the object has one at all. The taskbar
  #   state concerns compare against these to tell a value the user typed from one the object
  #   already holds (see FormUpdater::Concerns::StoresTaskbarState#should_store_field?).
  #
  # Attributes by default. A form whose fields are not attributes of its object overrides them —
  #   FormUpdater::Updater::KnowledgeBase::Answer::Edit does, where the title lives on a
  #   translation and the publication state is derived from three timestamps.
  def object_field?(field)
    object.respond_to?(field)
  end

  def object_field_value(field)
    object[field]
  end

  # And whether that value is the attribute of the same name, which is what lets the comparison
  #   below read both sides through the attribute's type. Overridden together with the two above:
  #   a field an override resolves belongs to that override, even where a column happens to carry
  #   the same name and would cast the value into something else.
  def object_field_attribute?(field)
    object.class.has_attribute?(field)
  end

  # Whether a submitted value differs from the object's own. The form sends JSON, so a date arrives
  #   as "2026-08-14" while the record holds a Date, and those two never compare equal - every round
  #   trip would report a change. A timestamp does compare equal, ActiveSupport coercing the string
  #   in Time#<=>, but only as far as the minute the form is able to express.
  def object_field_changed?(field, value)
    comparable_field_value(field, object_field_value(field)) != comparable_field_value(field, value)
  end

  # Both sides of that comparison read through the attribute's own type, so they are in the terms
  #   the record holds them in. Whole minutes for a timestamp, as
  #   PerformChanges::Action::AttributeUpdates#fetch_new_date_value does and for the same reason:
  #   FORMAT_DATETIME carries seconds in no locale but hu, so the field cannot express what the
  #   record holds below the minute. It costs hu a second-level edit going unstored in the draft.
  def comparable_field_value(field, value)
    return value if !object_field_attribute?(field)

    value = object.class.type_for_attribute(field).cast(value)

    value.acts_like?(:time) ? value.change(usec: 0, sec: 0) : value
  end

  def resolve_relation_fields
    relation_fields.each do |name, relation_field|
      relation_resolver = get_relation_resolver(relation_field)

      result_initialize_field(name)

      result[relation_field[:name]][:options] = relation_resolver.options

      ensure_field_value_int(result[relation_field[:name]])
    end
  end

  def ensure_field_value_int(field)
    return if field[:value].blank?

    field[:value] = field[:value].to_i
  end

  RELATION_CLASS_PREFIX = 'FormUpdater::Relation::'.freeze

  def get_relation_resolver(relation_field)
    relation_class = "#{RELATION_CLASS_PREFIX}#{relation_field[:name].humanize}".safe_constantize
    if !relation_class
      relation_class = "#{RELATION_CLASS_PREFIX}#{relation_field[:relation]}".constantize
    end

    relation_class.new(
      context:      context,
      current_user: current_user,
      data:         data,
      filter_ids:   relation_field[:filter_ids],
    )
  rescue
    raise "Cannot resolve relation type #{relation_field[:relation]} (#{relation_field[:name]})."
  end

  def result_initialize_field(name)
    result[name] ||= {}
  end
end

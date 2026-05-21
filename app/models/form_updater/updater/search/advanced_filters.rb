# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Form updater for the desktop advanced search filter form.
#
# Relation-typed filter fields (e.g. group/state/priority) live as sub-fields
# *inside* the FieldFilterSelector rather than at the form's top level, so the
# default relation-resolution path can't reach them. The frontend tells us
# which active filter rows need resolution via `meta.additionalData`:
#
#   {
#     entity:               'Ticket' | 'User' | 'Organization',
#     filterRelationFields: [{ name: 'ticket.group_id', relation: 'Group' }, ...]
#   }
#
# We dispatch each entry through the standard `get_relation_resolver` (so we
# reuse FormUpdater::Relation::* including Relation::Group's tree handling)
# and collect the resulting options into `result['filters']
# [:filterAttributeOptions]`, keyed by the dotted attribute name.
class FormUpdater::Updater::Search::AdvancedFilters < FormUpdater::Updater

  # Mirrors the desktop search plugins (Search/plugins/{ticket,user,
  # organization}.ts). The current form's entity comes in via meta and the
  # user is authorized against the entity's permission set.
  # TODO: maybe we need later a more generic approach?
  ENTITY_PERMISSIONS = {
    'Ticket'       => %w[ticket.agent ticket.customer],
    'User'         => %w[ticket.agent admin.user],
    'Organization' => %w[ticket.agent admin.organization],
  }.freeze

  def object_type
    nil
  end

  def authorized?
    return false if entity_permissions.nil?

    current_user.permissions?(entity_permissions)
  end

  def resolve
    resolve_filter_attribute_options

    super
  end

  private

  def entity
    @entity ||= meta.dig(:additional_data, 'entity')
  end

  def entity_permissions
    @entity_permissions ||= ENTITY_PERMISSIONS[entity]
  end

  def filter_relation_fields
    @filter_relation_fields ||= meta.dig(:additional_data, 'filterRelationFields')
  end

  def resolve_filter_attribute_options
    return if filter_relation_fields.blank?

    entity_prefix = "#{entity.to_s.downcase}."
    options_by_attribute = {}

    filter_relation_fields.each do |field|
      # `meta.additional_data` is an untyped JSON blob, so the entry could
      # in theory be anything. Only guard against a non-Hash here to avoid
      # crashing the whole loop; the FE controls the inner shape.
      next if !field.is_a?(Hash)

      attribute_name = field['name']
      next if attribute_name.blank?

      # Defense in depth: the FE Form is per-entity, so every filter relation
      # it sends must belong to the form's entity. Drop foreign-entity entries.
      # TODO: we maybe need a better way for all this situation (also for the main form updater relation handling).
      next if !attribute_name.start_with?(entity_prefix)

      options = options_for_relation(field)
      next if options.nil?

      options_by_attribute[attribute_name] = options
    end

    return if options_by_attribute.empty?

    result['filters'] = {
      filterAttributeOptions: options_by_attribute,
    }
  end

  def options_for_relation(field)
    return if field['relation'].blank?

    relation_field = {
      name:     field['name'].split('.', 2).last,
      relation: field['relation'],
    }

    get_relation_resolver(relation_field).options
  rescue
    # TODO: can maybe be removed when relation stuff is in frontend better solved (e.g. when autcomplete should be used)
    # An unsupported relation type or an internal lookup failure should not
    # break the whole form-updater response — just skip those options.
    nil
  end
end

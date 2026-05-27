# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Form updater for the desktop advanced search filter form.
#
# Relation-typed filter fields (e.g. group/state/priority) and autocomplete
# fields (customer/organization/owner) live as sub-fields *inside* the
# FieldFilterSelector rather than at the form's top level, so the default
# relation- and apply-value-resolution paths can't reach them. The frontend
# tells us which active filter rows need resolution via `meta.additionalData`:
#
#   {
#     entity:                   'Ticket' | 'User' | 'Organization',
#     filterRelationFields:     [{ name: 'ticket.group_id', relation: 'Group' }, ...],
#     filterAutocompleteFields: [
#       { name: 'ticket.owner_id',    autocompleteFilterType: 'agent' },
#       { name: 'ticket.customer_id', autocompleteFilterType: 'customer' },
#     ],
#   }
#
# Relation entries dispatch through the standard `get_relation_resolver` (so
# we reuse FormUpdater::Relation::* including Relation::Group's tree handling).
# Autocomplete entries dispatch through the apply-value autocomplete handlers
# (so the option shape and serializer stay single-sourced with the top-level
# field path) — the meta only carries the row's name + type; the IDs to
# resolve come from the form's `data['filters']` payload, matched by name.
# Both sides collect into `result['filters'][:filterAttributeOptions]` keyed
# by the dotted attribute name.
class FormUpdater::Updater::Search::AdvancedFilters < FormUpdater::Updater

  # Mirrors the desktop search plugins (Search/plugins/{ticket,user,
  # organization}.ts). The current form's entity comes in via meta and the
  # user is authorized against the entity's permission set.
  # TODO: maybe we need later a more generic approach?
  ENTITY_PERMISSIONS = {
    'Ticket'       => %w[ticket.agent],
    'User'         => %w[ticket.agent admin.user],
    'Organization' => %w[ticket.agent admin.organization],
  }.freeze

  # Routes a filter row's `autocompleteFilterType` (set by the resolver's
  # `getFilterAutocompleteType()`) to the apply-value handler whose
  # `resolve_option` method builds the option entry. Customer and agent share
  # the User handler — the option shape is identical, only the search query
  # differs, and we're resolving known IDs here, not searching.
  AUTOCOMPLETE_OPTION_HANDLERS = {
    'customer'     => FormUpdater::ApplyValue::UserAutocomplete,
    'agent'        => FormUpdater::ApplyValue::UserAutocomplete,
    'organization' => FormUpdater::ApplyValue::OrganizationAutocomplete,
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

  def filter_autocomplete_fields
    @filter_autocomplete_fields ||= meta.dig(:additional_data, 'filterAutocompleteFields')
  end

  def resolve_filter_attribute_options
    options_by_attribute = {}
    options_by_attribute.merge!(resolve_relation_options)
    options_by_attribute.merge!(resolve_autocomplete_options)

    return if options_by_attribute.empty?

    result['filters'] = {
      filterAttributeOptions: options_by_attribute,
    }
  end

  def resolve_relation_options
    return {} if filter_relation_fields.blank?
    # Relation option lists (group/state/priority/…) don't depend on the
    # current filter values, so resolving them once at form mount is enough.
    # Subsequent form-updater runs (triggered by external value changes such
    # as cross-tab sync) skip this branch — only the autocomplete branch
    # re-resolves the newly-arriving IDs.
    return {} if !meta[:initial]

    options_by_attribute = {}
    filter_relation_fields.each do |field|
      # `meta.additional_data` is an untyped JSON blob, so the entry could
      # in theory be anything. Only guard against a non-Hash here to avoid
      # crashing the whole loop; the FE controls the inner shape.
      next if !field.is_a?(Hash)

      attribute_name = field['name']
      next if attribute_name.blank?
      next if !attribute_belongs_to_entity?(attribute_name)

      options = options_for_relation(field)
      next if options.nil?

      options_by_attribute[attribute_name] = options
    end
    options_by_attribute
  end

  def resolve_autocomplete_options
    return {} if filter_autocomplete_fields.blank?

    options_by_attribute = {}
    filter_autocomplete_fields.each do |field|
      next if !field.is_a?(Hash)

      attribute_name = field['name']
      next if attribute_name.blank?
      next if !attribute_belongs_to_entity?(attribute_name)

      options = options_for_autocomplete(field)
      next if options.blank?

      options_by_attribute[attribute_name] = options
    end
    options_by_attribute
  end

  # Defense in depth: the FE Form is per-entity, so every filter row it
  # sends must belong to the form's entity. Drop foreign-entity entries.
  # TODO: we maybe need a better way for all this situation (also for the main form updater relation handling).
  def attribute_belongs_to_entity?(attribute_name)
    attribute_name.start_with?("#{entity.to_s.downcase}.")
  end

  def options_for_relation(field)
    return if field['relation'].blank?

    relation_field = {
      name:     field['name'].split('.', 2).last,
      relation: field['relation'],
    }

    get_relation_resolver(relation_field).options
  end

  def options_for_autocomplete(field)
    handler = AUTOCOMPLETE_OPTION_HANDLERS[field['autocompleteFilterType']]
    return if handler.nil?

    ids = Array.wrap(filter_row_value(field['name'])).compact
    return if ids.empty?

    ids.filter_map { |id| handler.resolve_option(id) }
  end

  # The form's `data` payload is the canonical source of filter row values
  # (the FE writes them there as it tracks the FilterFieldSelector input).
  # Look up the current row's value by its dotted attribute name rather than
  # threading it through the meta — keeps the meta describing structure only,
  # avoids a duplicate-of-truth between meta and data.
  def filter_row_value(attribute_name)
    rows = data&.dig('filters') || data&.dig(:filters)
    return if !rows.is_a?(Array)

    row = rows.find { |entry| entry.is_a?(Hash) && (entry['name'] || entry[:name]) == attribute_name }
    return if row.nil?

    row['value'] || row[:value]
  end
end

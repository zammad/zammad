# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The Core Workflow actions checked for every attribute type, with one field per
#   action. spec/system/examples/core_workflow_examples.rb checks them in the
#   browser, spec/models/core_workflow/attribute_types_spec.rb in the backend.
#
# Include it into an example group that defines `object_name` and `matrix_type`.
module CoreWorkflowFieldMatrix
  # show, set_optional and unset_readonly undo an earlier rule, as their result is
  #   also the state of a field without any workflow.
  FIELD_STATE_PERFORMS = {
    show:           [{ operator: 'hide', hide: 'true' }, { operator: 'show', show: 'true' }],
    hide:           [{ operator: 'hide', hide: 'true' }],
    remove:         [{ operator: 'remove', remove: 'true' }],
    set_optional:   [{ operator: 'set_mandatory', set_mandatory: 'true' }, { operator: 'set_optional', set_optional: 'true' }],
    set_mandatory:  [{ operator: 'set_mandatory', set_mandatory: 'true' }],
    unset_readonly: [{ operator: 'set_readonly', set_readonly: 'true' }, { operator: 'unset_readonly', unset_readonly: 'true' }],
    set_readonly:   [{ operator: 'set_readonly', set_readonly: 'true' }],
  }.freeze

  FILL_IN_PERFORMS = {
    fill_in:                     [{ operator: 'fill_in', fill_in: '4cddb2twza' }],
    fill_in_empty_with_match:    [{ operator: 'fill_in_empty', fill_in_empty: '9999' }],
    fill_in_empty_without_match: [
      { operator: 'fill_in', fill_in: '4cddb2twza' },
      { operator: 'fill_in_empty', fill_in_empty: '9999' },
    ],
  }.freeze

  def self.option_performs(restrict:, select:, auto_select:)
    {
      restrict_values: [{ operator: 'set_fixed_to', set_fixed_to: restrict }],
      select:          [{ operator: 'select', select: [select] }],
      auto_select:     [
        { operator: 'set_fixed_to', set_fixed_to: ['', auto_select] },
        { operator: 'auto_select', auto_select: 'true' },
      ],
    }
  end

  KEY_OPTION_PERFORMS = option_performs(restrict: %w[key_1 key_3], select: 'key_3', auto_select: 'key_3').freeze

  TREE_OPTION_PERFORMS = option_performs(
    restrict:    ['Incident', 'Incident::Hardware', 'Incident::Hardware::Monitor'],
    select:      'Incident::Hardware::Monitor',
    auto_select: 'Incident',
  ).freeze

  TYPES = {
    input:             { factory: :object_manager_attribute_text, performs: FIELD_STATE_PERFORMS.merge(FILL_IN_PERFORMS) },
    textarea:          { factory: :object_manager_attribute_textarea, performs: FIELD_STATE_PERFORMS.merge(FILL_IN_PERFORMS) },
    select:            { factory: :object_manager_attribute_select, performs: FIELD_STATE_PERFORMS.merge(KEY_OPTION_PERFORMS) },
    multiselect:       { factory: :object_manager_attribute_multiselect, performs: FIELD_STATE_PERFORMS.merge(KEY_OPTION_PERFORMS) },
    boolean:           {
      factory:  :object_manager_attribute_boolean,
      performs: FIELD_STATE_PERFORMS.except(:unset_readonly, :set_readonly)
        .merge(option_performs(restrict: %w[false], select: 'true', auto_select: 'false')),
    },
    tree_select:       { factory: :object_manager_attribute_tree_select, performs: FIELD_STATE_PERFORMS.merge(TREE_OPTION_PERFORMS) },
    multi_tree_select: { factory: :object_manager_attribute_multi_tree_select, performs: FIELD_STATE_PERFORMS.merge(TREE_OPTION_PERFORMS) },
    date:              { factory: :object_manager_attribute_date, performs: FIELD_STATE_PERFORMS },
    datetime:          { factory: :object_manager_attribute_datetime, performs: FIELD_STATE_PERFORMS },
  }.freeze

  SCREENS = {
    create_middle: { '-all-' => { shown: true, required: false } },
    create:        { '-all-' => { shown: true, required: false } },
    edit:          { '-all-' => { shown: true, required: false } },
  }.freeze

  def matrix_performs
    TYPES.fetch(matrix_type)[:performs]
  end

  def matrix_field(action)
    @matrix_field_prefix ||= "cw#{SecureRandom.hex(5)}"

    "#{@matrix_field_prefix}_#{action}"
  end

  # The including example groups reset the schema with db_strategy: :reset.
  def create_matrix_fields
    matrix_performs.each_key do |action|
      create(TYPES.fetch(matrix_type)[:factory],
             object_name: object_name,
             name:        matrix_field(action),
             display:     matrix_field(action),
             screens:     SCREENS)
    end
    ObjectManager::Attribute.migration_execute # rubocop:disable Zammad/ExistsDbStrategy
  end

  def create_matrix_workflows
    matrix_performs.each do |action, rules|
      rules.each do |rule|
        create(:core_workflow,
               object:  object_name,
               perform: { "#{object_name.downcase}.#{matrix_field(action)}": rule })
      end
    end
  end
end

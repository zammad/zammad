# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::ChecksCoreWorkflow
  extend ActiveSupport::Concern

  class_methods do
    def core_workflow_screen(screen)
      @core_workflow_screen ||= screen
    end
  end

  def validate_workflows
    return if !self.class.instance_variable_get(:@core_workflow_screen)

    perform_result = CoreWorkflow.perform(payload: perform_payload, user: current_user, assets: false, form_updater: true)
    return if perform_result.blank?

    FormUpdater::CoreWorkflow.perform_mapping(perform_result, result, relation_fields:, object:, field_types:)

    sign_fixed_options(perform_result[:all_options].keys)

    return if perform_result[:flags].blank?

    @flags = @flags.merge(perform_result[:flags])
  end

  private

  # A field's own options cost next to nothing to build, so the list is its own signature: a form that holds it is
  #   spared the transfer only.
  def sign_fixed_options(names)
    names.each do |name|
      options = result.dig(name, :options)
      next if options.nil?

      result[name].delete(:options) if options_to_send(name, FormUpdater::OptionCache.signature(options)) { options }.nil?
    end
  end

  # A relation the field layer lists for the form: the records of Core Workflow's values it lets the user choose, so that
  #   the form and the layer's other clients offer the same records.
  def relation_options(relation_field)
    type = field_layer_relation(relation_field)
    return super if type.nil?

    options = type.option_list(allowed: relation_field[:filter_ids].map(&:to_s))

    FormUpdater::OptionList.form_options(options, integer: true, tree: options.any? { |option| option.children.any? })
  end

  def relation_options_key(relation_field)
    type = field_layer_relation(relation_field)
    return super if type.nil?

    type.option_list_key(allowed: relation_field[:filter_ids].map(&:to_s))
  end

  # @return [Service::EntityAttribute::Type::Relation, nil] nil for a relation the form's own relation classes list
  def field_layer_relation(relation_field)
    type = field_types[relation_field[:name]] if relation_field[:filter_ids]

    type if type.is_a?(Service::EntityAttribute::Type::Relation)
  end

  def field_types
    @field_types ||= FormUpdater::FieldTypes.new(object_type:, user: current_user, record: field_record)
  end

  # A new ticket's fields are those of a ticket not saved yet; a bulk edit changes several tickets, so none is the record.
  def field_record
    object || (object_type.new if self.class.instance_variable_get(:@core_workflow_screen) == 'create_middle')
  end

  def perform_payload
    # Copy data to avoid changing the original data inside core workflow.
    params = data.dup

    # Make sure that current values are used for the perform workflow.
    # For example: Apply template can change the values.
    result.each do |name, field|
      next if !field.key?(:value)

      params[name] = field[:value]
    end

    # The record core workflow works on is the authorized object, never an id from the form data
    #   or from values applied to it, like a taskbar state.
    params.delete('id')
    params['id'] = object.id if object

    # Currently we need to convert the relation field values (integer) to strings for the
    # current core workflow implementation.
    convert_relation_field_value(params)

    {
      'event'                  => 'core_workflow',
      'request_id'             => meta[:request_id],
      'class_name'             => object_type.to_s,
      'screen'                 => self.class.instance_variable_get(:@core_workflow_screen),
      'params'                 => params,
      'last_changed_attribute' => meta.dig(:changed_field, :name),
    }
  end

  def convert_relation_field_value(params)
    return if relation_fields.blank?

    relation_fields.each_key do |field_name|
      next if params[field_name].blank?

      params[field_name] = params[field_name].to_s
    end
  end
end

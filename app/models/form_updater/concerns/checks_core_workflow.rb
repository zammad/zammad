# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

    FormUpdater::CoreWorkflow.perform_mapping(perform_result, result, relation_fields: relation_fields)
  end

  private

  def perform_payload
    params = data

    # Add object id information for the perform worklow for already existing objects.
    if object
      params['id'] = object.id
    end

    # Make sure that current values are used for the perform workflow.
    # For example: Apply template can change the values.
    result.each do |name, field|
      next if !field.key?(:value)

      params[name] = field[:value]
    end

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

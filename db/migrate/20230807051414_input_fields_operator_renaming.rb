# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class InputFieldsOperatorRenaming < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_postmaster_filter
    update_core_workflows
  end

  private

  OPERATOR_MAPPING = {
    'is'          => 'is any of',
    'is not'      => 'is none of',
    'starts with' => 'starts with one of',
    'ends with'   => 'ends with one of',
  }.freeze

  def update_postmaster_filter
    PostmasterFilter.in_batches.each_record do |filter|
      next if filter.match.blank?

      filter.match.each_value do |condition|
        next if condition[:operator].blank?
        next if OPERATOR_MAPPING.keys.exclude?(condition[:operator])

        condition[:operator] = OPERATOR_MAPPING[condition[:operator]]
      end

      filter.save!
    end
  end

  def update_core_workflows
    CoreWorkflow.in_batches.each_record do |workflow|
      next if workflow.condition_saved.blank? && workflow.condition_selected.blank?

      update_core_workflow_condition(workflow, :condition_saved)
      update_core_workflow_condition(workflow, :condition_selected)
      workflow.save!
    end
  end

  def update_core_workflow_condition(workflow, condition_type)
    return if !input_operators_used?(workflow, condition_type)

    workflow[condition_type.to_sym].each do |attribute, condition|
      next if !operator_relevant?(condition[:operator])
      next if !input_attribute?(attribute)

      condition[:operator] = OPERATOR_MAPPING[condition[:operator]]
    end
  end

  def operator_relevant?(operator)
    return false if operator.blank?
    return false if OPERATOR_MAPPING.keys.exclude?(operator)

    true
  end

  def input_attribute?(attribute)
    meta_information = object_manager_attributes_type_lookup[attribute]
    return false if meta_information.nil?
    return false if !meta_information.eql?('input')

    true
  end

  def input_operators_used?(workflow, condition_type)
    workflow[condition_type.to_sym].values.any? do |condition|
      condition.key?(:operator) && condition[:operator].present? && OPERATOR_MAPPING.key?(condition[:operator])
    end
  end

  def object_manager_attributes_type_lookup
    @object_manager_attributes_type_lookup ||= begin
      ObjectManager::Attribute.all.each_with_object({}) do |attribute, hash|
        object_name = ObjectLookup.by_id(attribute.object_lookup_id)

        if object_name.casecmp('ticketarticle').zero?
          object_name = 'article'
        end

        hash["#{object_name.downcase}.#{attribute.name}"] = attribute.data_type
      end
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class RegexOperatorRenaming < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_time_accounting_selector
    update_core_workflows
  end

  private

  OPERATOR_MAPPING = {
    'regex match'    => 'matches regex',
    'regex mismatch' => 'does not match regex',
  }.freeze

  def update_time_accounting_selector
    selector = Setting.get('time_accounting_selector')
    return if selector.blank?
    return if selector[:condition].blank?

    selector[:condition].each_value do |value|
      next if value[:operator].blank?
      next if OPERATOR_MAPPING.keys.exclude?(value[:operator])

      value[:operator] = OPERATOR_MAPPING[value[:operator]]
    end

    Setting.set('time_accounting_selector', selector)
  end

  def update_core_workflows
    CoreWorkflow.in_batches.each_record do |workflow|
      next if workflow.condition_saved.blank? && workflow.condition_selected.blank?

      update_condition(workflow, :condition_saved)
      update_condition(workflow, :condition_selected)
      workflow.save!
    end
  end

  def update_condition(workflow, condition_type)
    return if !regex_operators_used?(workflow, condition_type)

    workflow[condition_type.to_sym].each_value do |condition|
      next if condition[:operator].blank?
      next if OPERATOR_MAPPING.keys.exclude?(condition[:operator])

      condition[:operator] = OPERATOR_MAPPING[condition[:operator]]
    end
  end

  def regex_operators_used?(workflow, condition_type)
    workflow[condition_type.to_sym].values.any? do |condition|
      condition.key?(:operator) && condition[:operator].present? && OPERATOR_MAPPING.key?(condition[:operator])
    end
  end
end

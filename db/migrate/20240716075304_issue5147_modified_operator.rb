# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Issue5147ModifiedOperator < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    map_operator = {
      'has changed' => 'just changed',
      'changed to'  => 'just changed to',
    }

    CoreWorkflow.find_each do |core_workflow|
      %i[condition_saved condition_selected].each do |column|
        core_workflow[column].each do |key, value|
          next if value.blank?
          next if map_operator.keys.exclude?(value[:operator])

          core_workflow[column][key][:operator] = map_operator[value[:operator]]
        end
      end

      core_workflow.save!
    end
  end
end

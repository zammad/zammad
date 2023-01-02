# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom::AdminCoreWorkflow < CoreWorkflow::Custom::Backend
  def saved_attribute_match?
    object?(CoreWorkflow)
  end

  def selected_attribute_match?
    object?(CoreWorkflow)
  end

  def perform
    perform_object_defaults
    perform_screen_by_object
  end

  def perform_object_defaults
    result('set_fixed_to', 'object', ['', 'Ticket', 'Organization', 'User', 'Group'])
  end

  def perform_screen_by_object
    if selected.object.blank?
      result('set_fixed_to', 'preferences::screen', [''])
      return
    end

    result('set_fixed_to', 'preferences::screen', screens_by_object.uniq)
  end

  def screens_by_object
    result = []
    ObjectManager::Object.new(selected.object).attributes(@condition_object.user).each do |field|
      result += field[:screen].keys
    end
    result
  end
end

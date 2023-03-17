# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::HasChanged < CoreWorkflow::Condition::Backend
  def match
    return if @condition_object.payload['last_changed_attribute'] != field

    true
  end
end

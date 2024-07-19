# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::JustChanged < CoreWorkflow::Condition::Backend
  def match
    return if @condition_object.payload['last_changed_attribute'] != field

    true
  end
end

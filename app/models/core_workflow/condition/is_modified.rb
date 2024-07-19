# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::IsModified < CoreWorkflow::Condition::Backend
  def match
    return true if changes[field].present? && value_valid?

    false
  end

  def value_valid?
    return true if selected.persisted?
    return false if changes[field][1].blank?
    return false if changes[field][1] == 1 && field == 'owner_id'
    return false if @condition_object.attribute_object.object_elements_hash[field][:default] == changes[field][1]

    true
  end

  def changes
    @changes ||= selected.changes
  end
end

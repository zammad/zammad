# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context::Entity::ObjectAttributes::Default < Service::AI::Agent::Run::Context::Entity::ObjectAttributes
  def self.applicable?(_object_attribute)
    true
  end

  def prepare
    return if entity_value.blank?

    {
      value: entity_value,
    }
  end
end

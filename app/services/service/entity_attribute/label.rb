# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The label of a field's stored value, as a person reads it: an option by its label, a record by its name, a time in
#   the system's time zone; nil for an empty value and for a record the user may not see.
class Service::EntityAttribute::Label < Service::Base
  requires_current_user!

  attr_reader :attribute, :value

  # @param attribute [ObjectManager::Attribute] the field
  def initialize(attribute:, value:)
    @attribute = attribute
    @value     = value
  end

  def execute
    return if value.nil? || value == '' || value == []

    Service::EntityAttribute::Type.for(attribute, user: current_user).label(value)
  end
end

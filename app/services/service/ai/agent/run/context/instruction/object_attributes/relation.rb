# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context::Instruction::ObjectAttributes::Relation < Service::AI::Agent::Run::Context::Instruction::ObjectAttributes
  ALLOWED_RELATIONS = %w[Group TicketState TicketPriority].freeze

  def self.applicable?(object_attribute)
    object_attribute.data_option[:relation].present? && ALLOWED_RELATIONS.include?(object_attribute.data_option[:relation])
  end

  def prepare_for_instruction
    items.map do |item|
      result = {
        value: item.id,
        label: item.name,
      }

      # Add description if available in filter_values
      description = find_description_for_item(item)

      result[:description] = description if description.present?

      result
    end
  end

  private

  def find_description_for_item(item)
    return filter_values[item.id.to_s] if filter_values.key?(item.id.to_s)
    return filter_values[item.id] if filter_values.key?(item.id)

    nil
  end

  # Every record the field may hold, the admin's choice of them where given, in the order the database returns them, as
  #   the instructions have listed them so far.
  def items
    @items ||= type.records(allowed: filter_keys.presence&.map(&:to_s)).reorder(nil)
  end
end

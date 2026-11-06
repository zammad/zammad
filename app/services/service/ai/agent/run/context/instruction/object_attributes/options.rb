# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context::Instruction::ObjectAttributes::Options < Service::AI::Agent::Run::Context::Instruction::ObjectAttributes
  def self.applicable?(object_attribute)
    object_attribute.data_option[:options].present? && object_attribute.data_option[:relation].blank?
  end

  def prepare_for_instruction
    choices.map do |value, label|
      result = { value:, label: }

      description = filter_values[value]
      result[:description] = description if description.present?

      result
    end
  end

  private

  # The field layer's list in the admin's order, narrowed to the admin's choice and in its order where given; options
  #   kept as an array — a tree, or a list in an order of its own — by their values, as the instructions have named them.
  def choices
    pairs = Service::EntityAttribute::Option.flatten(type.option_list || []).reject(&:disabled).to_h { |option| [option.value, option.label] }
    return tree_choices(pairs) if object_attribute.data_option[:options].is_a?(Array)

    filter_keys.present? ? pairs.slice(*filter_keys.map(&:to_s)).to_a : pairs.to_a
  end

  def tree_choices(pairs)
    pairs = pairs.slice(*pairs.keys.intersection(filter_keys.map(&:to_s))) if filter_keys.present?

    pairs.keys.map { |value| [value, value] }
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Perform::Agent < SimpleDelegator

  attr_reader :ai_result

  def initialize(ai_agent:, ai_result:)
    @ai_result = ai_result

    super(ai_agent)
  end

  # For now we are directly returning the mapping
  def perform
    @perform ||= begin
      action_mapping = prepare_action_mapping

      interpolator = Service::Template::Interpolation::Interpolator::AIAgent.new(
        template:                       action_mapping.to_json,
        tracks:                         {},
        additional_track_generate_data: {
          result_structure: execution_definition['result_structure'],
          ai_agent_result:  ai_result_content,
        },
      )

      interpolator.execute
    end
  end

  def class
    __getobj__.class
  end

  private

  def prepare_action_mapping
    # Start with the base mapping
    mapping = execution_action_definition['mapping'] || {}

    # Process conditions if they exist
    conditions = execution_action_definition['conditions']
    return mapping if ai_result_content.blank? || conditions.blank?

    conditions.each do |item|
      next if item['condition'].blank? || item['mapping'].blank?

      if condition_matches?(item['condition'])
        mapping.merge!(item['mapping'])
      end
    end

    mapping
  end

  def condition_matches?(condition)
    return false if !condition.is_a?(Hash)

    return false if ai_result_content.blank?

    condition.each do |key, expected_value|
      # Check if the key exists in ai_result_content
      return false if !ai_result_content.key?(key)

      actual_value = ai_result_content[key]

      # If the key doesn't exist, the condition doesn't match.
      return false if actual_value.nil?

      return false if actual_value != expected_value
    end

    true
  end

  def ai_result_content
    @ai_result_content ||= ai_result&.content
  end
end

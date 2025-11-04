# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Template::Interpolation::Interpolator::AIAgent::Track::AIAgentResult < Service::Template::Interpolation::Engine::Track
  class << self
    attr_reader :result_structure

    def root?
      true
    end

    def klass
      'Struct::AIAgentResult'
    end

    def functions
      return ['content'] if result_structure.blank?

      result_structure.keys
    end

    def replacements(result_structure:)
      # Save the result structure for the functions method.
      @result_structure = result_structure

      {
        ai_agent_result: functions,
      }
    end

    def generate(tracks, data)
      ai_agent_result = data[:ai_agent_result]
      return if ai_agent_result.blank?

      # Save the result structure for the functions method.
      @result_structure = data[:result_structure]

      tracks[:ai_agent_result] = if result_structure.blank?
                                   result_struct = Struct.new('AIAgentResult', :content)
                                   result_struct.new(ai_agent_result)
                                 else
                                   result_struct = Struct.new('AIAgentResult', *result_structure.keys.map(&:to_sym))

                                   # Ensure values are passed in the correct order by mapping them to the result_structure keys.
                                   values = result_structure.keys.map { |key| ai_agent_result[key] }
                                   result_struct.new(*values)
                                 end
    end
  end
end

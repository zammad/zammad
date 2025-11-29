# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Service::AIAgent < AI::Service
  def self.lookup_attributes(context_data, _locale)
    {
      identifier:   'ai_agent',
      triggered_by: context_data[:ai_agent],
    }
  end

  def self.lookup_version(context_data, _locale)
    "#{context_data[:ai_agent].id}-#{context_data[:ai_agent].cache_version}"
  end

  def analytics?
    true
  end

  private

  def options
    {
      temperature: 0.3,
    }
  end

  def json_response?
    additional_options[:json_response]
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Service::AIAgent < AI::Service
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

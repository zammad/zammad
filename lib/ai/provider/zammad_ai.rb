# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::ZammadAI < AI::Provider
  ZAMMAD_AI_API_BASE_URL = 'https://ai.zammad.com'.freeze

  def chat(prompt_system:, prompt_user:)
    service_name = options[:service_name] || 'generic'

    request_body = {
      system_prompt: prompt_system,
      prompt:        prompt_user,
    }

    if options[:model]
      request_body[:llm] = options[:model]
    end

    response = UserAgent.post(
      "#{self.class.base_url(config)}/api/v1/features/#{service_name.underscore}",
      request_body,
      {
        open_timeout:  4,
        read_timeout:  60,
        verify_ssl:    true,
        bearer_token:  self.class.token(config),
        total_timeout: 60,
        json:          true,
        log:           {
          facility: 'AI::Provider',
        },
      },
    )

    data = validate_response!(response)
    extract_response_metadata(data)

    data.first['response']
  end

  def embeddings(input:)
    raise 'not implemented yet due to missing API'
  end

  def self.ping!(config)
    response = UserAgent.get(
      "#{base_url(config)}/api/v1/me",
      {},
      {
        open_timeout:  4,
        read_timeout:  60,
        verify_ssl:    true,
        bearer_token:  token(config),
        total_timeout: 60,
        json:          true,
        log:           {
          facility:          'AI::Provider',
          log_only_on_error: true,
        },
      },
    )

    raise AI::Provider::ResponseError, __('API server not accessible') if response.code.to_i != 200

    nil
  end

  def self.base_url(config)
    ENV['ZAMMAD_AI_API_URL'] || config[:url] || ZAMMAD_AI_API_BASE_URL
  end

  def self.token(config)
    config[:token].presence || ENV['ZAMMAD_AI_TOKEN']
  end

  private

  def extract_response_metadata(data)
    @response_metadata = {
      model:          data.first['model'],
      total_duration: data.first['total_duration'],
    }
  end
end

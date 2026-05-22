# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::ZammadAI < AI::Provider
  ZAMMAD_AI_API_BASE_URL = 'https://ai.zammad.com'.freeze

  def chat(prompt_system:, prompt_user:, prompt_image:)
    service_name = options[:service_name] || 'generic'

    request_body = {
      system_prompt: prompt_system,
      prompt:        prompt_user,
    }

    if options[:model]
      request_body[:llm] = options[:model]
    end

    if prompt_image.is_a?(::Store)
      request_body[:images] = [Base64.strict_encode64(prompt_image.content_ocr)]
    end

    response = UserAgent.post(
      "#{self.class.base_url(config)}/api/v1/features/#{service_name.underscore}",
      request_body,
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl:   true,
        bearer_token: self.class.token(config),
        json:         true,
        log:          {
          facility: 'AI::Provider',
        },
      },
    )

    data = validate_response!(response)
    extract_response_metadata(data)

    data.first['response']
  end

  def embeddings(input:)
    raise NotImplementedError, 'not implemented yet due to missing API'
  end

  def self.ping!(config)
    response = UserAgent.get(
      "#{base_url(config)}/api/v1/me",
      {},
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl:   true,
        bearer_token: token(config),
        json:         true,
        log:          {
          facility:          'AI::Provider',
          log_only_on_error: true,
        },
      },
    )

    validate_response!(response)

    nil
  end

  def self.base_url(config)
    ENV['ZAMMAD_AI_API_URL'] || config[:url] || ZAMMAD_AI_API_BASE_URL
  end

  def self.token(config)
    ENV['ZAMMAD_AI_TOKEN'] || config[:token]
  end

  private

  def extract_response_metadata(data)
    @response_metadata = {
      model:             data.first['model'],
      prompt_tokens:     data.first.dig('usage', 'prompt_tokens'),
      completion_tokens: data.first.dig('usage', 'completion_tokens'),
      total_tokens:      data.first.dig('usage', 'total_tokens'),
    }
  end
end

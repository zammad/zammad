# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::Mistral < AI::Provider
  MISTRAL_API_BASE_URL = 'https://api.mistral.ai/v1'.freeze

  # default model also in app/assets/javascripts/app/lib/app_post/ai_provider/mistral.coffee
  DEFAULT_OPTIONS = {
    temperature:     0.1,
    model:           'mistral-medium-latest',
    embedding_model: 'mistral-embed',
  }.freeze

  EMBEDDING_SIZES = {
    'mistral-embed' => 1024
  }.freeze

  def chat(prompt_system:, prompt_user:)
    request_body = {
      model:           options[:model],
      messages:        [
        {
          role:    'system',
          content: prompt_system,
        },
        {
          role:    'user',
          content: prompt_user,
        },
      ],
      response_format: {
        type: options[:json_response] ? 'json_object' : 'text'
      },
    }

    response = UserAgent.post(
      "#{MISTRAL_API_BASE_URL}/chat/completions",
      request_body,
      {
        open_timeout:  4,
        read_timeout:  60,
        verify_ssl:    true,
        bearer_token:  config[:token],
        total_timeout: 60,
        json:          true,
        log:           {
          facility: 'AI::Provider',
        },
      },
    )

    data = validate_response!(response)
    extract_response_metadata(data)

    data['choices'].first['message']['content']
  end

  def embeddings(input:)
    response = UserAgent.post(
      "#{MISTRAL_API_BASE_URL}/embeddings",
      {
        model: options[:embedding_model] || DEFAULT_OPTIONS[:embedding_model],
        input: input,
      },
      {
        open_timeout:  4,
        read_timeout:  60,
        verify_ssl:    true,
        bearer_token:  config[:token],
        total_timeout: 60,
        json:          true,
      },
    )

    data = validate_response!(response)
    data['data'].first['embedding']
  end

  def self.ping!(config)
    response = UserAgent.get(
      "#{MISTRAL_API_BASE_URL}/models",
      {},
      {
        open_timeout:  4,
        read_timeout:  60,
        verify_ssl:    true,
        bearer_token:  config[:token],
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

  private

  def specific_metadata
    {
      model: options[:model],
    }
  end

  def extract_response_metadata(data)
    @response_metadata = {
      prompt_tokens:     data.dig('usage', 'prompt_tokens'),
      completion_tokens: data.dig('usage', 'completion_tokens'),
      total_tokens:      data.dig('usage', 'total_tokens'),
    }
  end
end

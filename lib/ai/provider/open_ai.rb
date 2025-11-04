# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::OpenAI < AI::Provider
  OPENAI_API_BASE_URL = 'https://api.openai.com/v1'.freeze

  # default model also in app/assets/javascripts/app/lib/app_post/ai_provider/open_ai.coffee
  DEFAULT_OPTIONS = {
    temperature:                0.1,
    model:                      'gpt-4.1',
    embedding_model:            'text-embedding-3-small',
    models_without_temperature: ['gpt-5']
  }.freeze

  EMBEDDING_SIZES = {
    'text-embedding-3-small' => 1536
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
      stream:          false,
      store:           false,
    }

    # Only include temperature if the model supports it
    request_body[:temperature] = options[:temperature] if model_supports_temperature?

    response = UserAgent.post(
      "#{OPENAI_API_BASE_URL}/chat/completions",
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
      "#{OPENAI_API_BASE_URL}/embeddings",
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
      "#{OPENAI_API_BASE_URL}/models",
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

  def model_supports_temperature?
    current_model = options[:model]

    # Check if any model in the list starts with the current model name
    options[:models_without_temperature].none? { |model_pattern| current_model.start_with?(model_pattern) }
  end

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

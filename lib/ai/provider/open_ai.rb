# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::OpenAI < AI::Provider
  OPENAI_API_BASE_URL = 'https://api.openai.com/v1'.freeze

  DEFAULT_OPTIONS = {
    temperature:     0.0,
    model:           'gpt-4o',
    embedding_model: 'text-embedding-3-small'
  }.freeze

  EMBEDDING_SIZES = {
    'text-embedding-3-small' => 1536
  }.freeze

  def chat(prompt_system:, prompt_user:)
    response = UserAgent.post(
      "#{OPENAI_API_BASE_URL}/chat/completions",
      {
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
        temperature:     options[:temperature],
        response_format: {
          type: options[:json_response] ? 'json_object' : 'text'
        },
        stream:          false,
        store:           false,
      },
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
          facility: 'AI::Provider',
        },
      },
    )

    raise AI::Provider::ResponseError, __('API server not accessible') if response.code.to_i != 200

    nil
  end
end

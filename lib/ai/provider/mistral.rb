# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::Mistral < AI::Provider
  include AI::Provider::Concerns::HandlesOpenAIMessages
  include AI::Provider::Concerns::HasConfigurableModel

  MISTRAL_API_BASE_URL = 'https://api.mistral.ai/v1'.freeze

  # default model also in app/assets/javascripts/app/lib/app_post/ai_provider/mistral.coffee
  DEFAULT_OPTIONS = {
    temperature:     0.1,
    model:           'mistral-large-2512',
    embedding_model: 'mistral-embed',
  }.freeze

  EMBEDDING_SIZES = {
    'mistral-embed' => 1024
  }.freeze

  EMBEDDING_INPUT_LIMITS = {
    'mistral-embed' => 8192
  }.freeze

  def self.ping!(config)
    response = UserAgent.get(
      "#{MISTRAL_API_BASE_URL}/models",
      {},
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl:   true,
        bearer_token: config[:token],
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

  private

  def chat(prompt_system:, prompt_user:, prompt_image:)
    request_body = {
      model:           model_for(prompt_image:),
      messages:        messages_for(prompt_system:, prompt_user:, prompt_image:),
      response_format: {
        type: options[:json_response] ? 'json_object' : 'text'
      },
    }

    response = UserAgent.post(
      "#{MISTRAL_API_BASE_URL}/chat/completions",
      request_body,
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl:   true,
        bearer_token: config[:token],
        json:         true,
        log:          {
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
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl:   true,
        bearer_token: config[:token],
        json:         true,
      },
    )

    data = validate_response!(response)
    data['data'].pluck('embedding')
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

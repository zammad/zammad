# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::OpenAI < AI::Provider
  include AI::Provider::Concerns::HandlesOpenAIMessages
  include AI::Provider::Concerns::HasConfigurableModel
  include AI::Provider::Concerns::HasModelsWithoutTemperatureFallback

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

  EMBEDDING_INPUT_LIMITS = {
    'text-embedding-3-small' => 8191
  }.freeze

  def self.supports_embeddings?
    true
  end

  def self.check_temperature_support!(config, related_object: nil)
    response = UserAgent.post(
      "#{OPENAI_API_BASE_URL}/chat/completions",
      {
        model:       config[:model] || DEFAULT_OPTIONS[:model],
        messages:    [{ role: 'user', content: 'Hello' }],
        temperature: DEFAULT_OPTIONS[:temperature],
        stream:      false,
        store:       false,
      },
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl:   true,
        bearer_token: config[:token],
        json:         true,
        log:          log_options(only_on_error: true, related_object:),
      },
    )

    return true if response.success?
    return false if temperature_unsupported?(response)

    # Not a temperature quirk but a broken config: raise with the mapped provider message.
    validate_response!(response)

    true
  rescue => e
    raise CheckTemperatureSupportError, e.message
  end

  private

  def chat(prompt_system:, prompt_user:, prompt_image:)
    request_body = {
      model:           model_for(prompt_image:),
      messages:        messages_for(prompt_system:, prompt_user:, prompt_image:),
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
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl:   true,
        bearer_token: config[:token],
        json:         true,
        log:          log_options,
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
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl:   true,
        bearer_token: config[:token],
        json:         true,
        log:          log_options,
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

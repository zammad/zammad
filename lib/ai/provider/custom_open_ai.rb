# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::CustomOpenAI < AI::Provider
  include AI::Provider::Concerns::HandlesOpenAIMessages
  include AI::Provider::Concerns::HasConfigurableModel
  include AI::Provider::Concerns::HasModelsWithoutTemperatureFallback

  DEFAULT_OPTIONS = {
    temperature:                0.1,
    models_without_temperature: ['gpt-5']
  }.freeze

  def chat(prompt_system:, prompt_user:, prompt_image:)
    request_body = {
      model:    model_for(prompt_image:),
      messages: messages_for(prompt_system:, prompt_user:, prompt_image:),
      stream:   false,
    }

    request_body[:temperature] = options[:temperature] if model_supports_temperature?

    request_options = {
      **REQUEST_TIMEOUT_OPTIONS,
      verify_ssl: true,
      json:       true,
      log:        log_options,
    }

    # Token is optional since target host might not require authentication
    request_options[:bearer_token] = config[:token] if config[:token].present?

    response = UserAgent.post(
      "#{config[:url]}/chat/completions",
      request_body,
      request_options,
    )

    data = validate_response!(response)
    extract_response_metadata(data)

    data['choices'].first['message']['content']
  end

  def embeddings(input:)
    raise NotImplementedError, 'not supported for custom OpenAI Compatible providers'
  end

  def self.check_temperature_support!(config, related_object: nil)
    request_body = {
      model:       config[:model],
      messages:    [{ role: 'user', content: 'Hello' }],
      temperature: DEFAULT_OPTIONS[:temperature],
      stream:      false,
    }

    request_options = {
      **REQUEST_TIMEOUT_OPTIONS,
      verify_ssl: true,
      json:       true,
      log:        log_options(only_on_error: true, related_object:),
    }

    # Token is optional since target host might not require authentication
    request_options[:bearer_token] = config[:token] if config[:token].present?

    response = UserAgent.post(
      "#{config[:url]}/chat/completions",
      request_body,
      request_options,
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

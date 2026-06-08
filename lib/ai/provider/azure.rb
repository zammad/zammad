# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::Azure < AI::Provider
  include AI::Provider::Concerns::HandlesOpenAIMessages

  def chat(prompt_system:, prompt_user:, prompt_image:)
    request_body = {
      messages:        messages_for(prompt_system:, prompt_user:, prompt_image:),
      response_format: {
        type: options[:json_response] ? 'json_object' : 'text'
      },
      stream:          false,
      store:           false,
    }

    request_body[:temperature] = options[:temperature] if model_supports_temperature?

    response = UserAgent.post(
      chat_url_for(prompt_image:),
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
      config[:url_embeddings],
      {
        input: input,
      },
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl:   true,
        bearer_token: config[:token],
        json:         true,
      },
    )

    # TODO: We cannot hardcode the embedding size here.
    # We need to get it from the request by counting the returned embeddings.
    # This should be part of the service that is used later.

    data = validate_response!(response)
    data['data'].first['embedding']
  end

  def self.ping!(config)
    url_models = config[:url_completions].gsub(%r{/deployments/.*$}, '/v1/models')

    response = UserAgent.get(
      url_models,
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

  def self.check_temperature_support!(config)
    response = UserAgent.post(
      config[:url_completions],
      {
        messages:    [{ role: 'user', content: 'Hello' }],
        temperature: 0.1,
        stream:      false,
        store:       false,
      },
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

    return true if response.success?

    data = JSON.parse(response.body)
    data = data.pop if data.is_a?(Array) # Handle case when response is an array of errors
    message = data.dig('error', 'message')
    type = data.dig('error', 'type')
    param = data.dig('error', 'param')
    code = data.dig('error', 'code')
    return false if type == 'invalid_request_error' && param == 'temperature' && code == 'unsupported_value'

    raise message
  rescue => e
    raise CheckTemperatureSupportError, e.message
  end

  def extract_response_metadata(data)
    @response_metadata = {
      model:             data['model'],
      prompt_tokens:     data.dig('usage', 'prompt_tokens'),
      completion_tokens: data.dig('usage', 'completion_tokens'),
      total_tokens:      data.dig('usage', 'total_tokens'),
    }
  end

  def chat_url_for(prompt_image:)
    return config[:url_completions] if !prompt_image.is_a?(::Store)

    config[:url_ocr] || config[:url_completions]
  end
end

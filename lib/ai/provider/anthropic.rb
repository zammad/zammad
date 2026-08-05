# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::Anthropic < AI::Provider
  include AI::Provider::Concerns::HasConfigurableModel
  include AI::Provider::Concerns::HasModelsWithoutTemperatureFallback

  ANTHROPIC_API_BASE_URL = 'https://api.anthropic.com/v1'.freeze

  # default model also in app/assets/javascripts/app/lib/app_post/ai_provider/anthropic.coffee
  DEFAULT_OPTIONS = {
    model:                      'claude-sonnet-4-6',
    max_tokens:                 1024,
    temperature:                0.0,
    models_without_temperature: [
      'claude-fable-5',
      'claude-opus-4-7',
      'claude-opus-4-8',
      'claude-opus-5',
      'claude-sonnet-5',
    ],
  }.freeze

  def chat(prompt_system:, prompt_user:, prompt_image:)

    # https://platform.claude.com/docs/en/build-with-claude/vision#base64-encoded-image-example
    content = if prompt_image.is_a?(::Store)
                [
                  {
                    type: 'text',
                    text: prompt_user,
                  },
                  {
                    type:   'image',
                    source: {
                      type:       'base64',
                      media_type: prompt_image.preferences['Content-Type'],
                      data:       Base64.strict_encode64(prompt_image.content_ocr)
                    },
                  },
                ]
              else
                prompt_user
              end

    request_body = {
      max_tokens: options[:max_tokens],
      messages:   [
        {
          role:    'user',
          content:,
        },
      ],
      model:      model_for(prompt_image:),
      stream:     false,
      system:     prompt_system,
    }

    request_body[:temperature] = options[:temperature] if model_supports_temperature?

    response = UserAgent.post(
      "#{ANTHROPIC_API_BASE_URL}/messages",
      request_body,
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl: true,
        headers:    headers,
        json:       true,
        log:        {
          facility: 'AI::Provider',
        },
      },
    )

    data = validate_response!(response)
    extract_response_metadata(data)

    data['content'].first['text']
  end

  def embeddings(input:)
    raise NotImplementedError, 'not implemented yet due to missing API'
  end

  def self.ping!(config)
    response = UserAgent.get(
      "#{ANTHROPIC_API_BASE_URL}/models",
      {},
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl: true,
        headers:    headers(config),
        json:       true,
        log:        {
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
      "#{ANTHROPIC_API_BASE_URL}/messages",
      {
        model:       config[:model] || DEFAULT_OPTIONS[:model],
        max_tokens:  1,
        messages:    [{ role: 'user', content: 'Hello' }],
        temperature: DEFAULT_OPTIONS[:temperature],
        stream:      false,
      },
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl: true,
        headers:    headers(config),
        json:       true,
        log:        {
          facility:          'AI::Provider',
          log_only_on_error: true,
        },
      },
    )

    return true if response.success?

    data  = JSON.parse(response.body.to_s)
    error = data.is_a?(Hash) ? data['error'] : nil
    return false if !error.is_a?(Hash)

    # Anthropic's error body has no param/code fields like OpenAI's, so this matches on the
    # error type plus the message mentioning temperature instead.
    return false if error['type'] == 'invalid_request_error' && error['message'].to_s.downcase.include?('temperature')

    raise error['message']
  rescue => e
    raise CheckTemperatureSupportError, e.message
  end

  def self.headers(config)
    {
      'Anthropic-Version' => '2023-06-01',
      'X-Api-Key'         => config[:token],
    }
  end

  private

  def specific_metadata
    {
      model: options[:model],
    }
  end

  def headers
    self.class.headers(config)
  end

  def extract_response_metadata(data)
    @response_metadata = {
      prompt_tokens:     data.dig('usage', 'input_tokens'),
      completion_tokens: data.dig('usage', 'output_tokens'),
      total_tokens:      data.dig('usage', 'input_tokens').to_i + data.dig('usage', 'output_tokens').to_i,
    }
  end
end

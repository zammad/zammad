# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::Azure < AI::Provider
  def chat(prompt_system:, prompt_user:)
    response = UserAgent.post(
      config[:url_completions],
      {
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
        open_timeout:  4,
        read_timeout:  60,
        verify_ssl:    true,
        bearer_token:  config[:token],
        total_timeout: 60,
        json:          true,
      },
    )

    # TODO: We cannot hardcode the embedding size here.
    # We need to get it from the request by counting the returned embeddings.
    # This should be part of the service that is used later.

    data = validate_response!(response)
    data['data'].first['embedding']
  end

  def self.ping!(config)
    ping_chat!(config)

    # TODO: Enable it when needed.
    # ping_embeddings!(config)

    nil
  end

  def self.ping_chat!(config)
    response = UserAgent.post(
      config[:url_completions],
      {
        messages:        [
          {
            role:    'system',
            content: 'Ping pong in JSON', # rubocop:disable Zammad/DetectTranslatableString
          },
          {
            role:    'user',
            content: 'Ping pong in JSON', # rubocop:disable Zammad/DetectTranslatableString
          },
        ],
        temperature:     0,
        response_format: {
          type: 'json_object'
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
          facility:          'AI::Provider',
          log_only_on_error: true,
        },
      },
    )

    raise AI::Provider::ResponseError, __('API server not accessible') if response.code.to_i != 200

    nil
  end

  def self.ping_embeddings!(config)
    response = UserAgent.post(
      config[:url_embeddings],
      {
        input: 'Ping',
      },
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

  private_class_method %i[ping_chat! ping_embeddings!]

  def extract_response_metadata(data)
    @response_metadata = {
      model:             data['model'],
      prompt_tokens:     data.dig('usage', 'prompt_tokens'),
      completion_tokens: data.dig('usage', 'completion_tokens'),
      total_tokens:      data.dig('usage', 'total_tokens'),
    }
  end
end

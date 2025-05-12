# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::Ollama < AI::Provider

  DEFAULT_OPTIONS = {
    model:           'llama3.2',
    temperature:     0.0,
    embedding_model: 'all-minilm',
  }.freeze

  EMBEDDING_SIZES = {
    'all-minilm'        => 384,
    'nomic-embed-text'  => 768,
    'mxbai-embed-large' => 1024,
  }.freeze

  def chat(prompt_system:, prompt_user:)
    params = {
      model:   options[:model],
      system:  prompt_system,
      prompt:  prompt_user,
      stream:  false,
      options: {
        temperature: options[:temperature],
      }
    }

    if options[:json_response]
      params[:format] = 'json'
    end

    response = UserAgent.post(
      "#{config[:url]}/api/generate",
      params,
      {
        open_timeout:  4,
        read_timeout:  60,
        verify_ssl:    true,
        total_timeout: 60,
        json:          true,
        log:           {
          facility: 'AI::Provider',
        },
      },
    )

    data = validate_response!(response)
    data['response']
  end

  def embeddings(input:)
    response = UserAgent.post(
      "#{config[:url]}/api/embed",
      {
        model: options[:embedding_model],
        input: input,
      },
      {
        open_timeout:  4,
        read_timeout:  60,
        verify_ssl:    true,
        total_timeout: 60,
        json:          true,
      },
    )

    data = validate_response!(response)
    data['response']['embeddings'].first
  end

  def self.ping!(config)
    response = UserAgent.get(
      config[:url],
      {},
      {
        open_timeout:  4,
        read_timeout:  60,
        verify_ssl:    true,
        total_timeout: 60,
        log:           {
          facility: 'AI::Provider',
        },
      },
    )

    raise AI::Provider::ResponseError, __('API server not accessible') if response.code.to_i != 200

    nil
  end
end

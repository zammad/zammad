# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::Ollama < AI::Provider
  include AI::Provider::Concerns::HasConfigurableModel

  # default model also in app/assets/javascripts/app/lib/app_post/ai_provider/ollama.coffee
  DEFAULT_OPTIONS = {
    model:           'mistral-small3.2',
    temperature:     0.0,
    embedding_model: 'all-minilm',
  }.freeze

  EMBEDDING_SIZES = {
    'all-minilm'        => 384,
    'nomic-embed-text'  => 768,
    'mxbai-embed-large' => 1024,
  }.freeze

  def chat(prompt_system:, prompt_user:, prompt_image:)
    params = {
      model:  model_for(prompt_image:),
      system: prompt_system,
      prompt: prompt_user,
      stream: false,
      think:  false,
    }

    if model_supports_temperature?
      params[:options] = { temperature: options[:temperature] }
    end

    if prompt_image.is_a?(::Store)
      params[:images] = [Base64.strict_encode64(prompt_image.content_ocr)]
    end

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
    extract_response_metadata(data)

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
          facility:          'AI::Provider',
          log_only_on_error: true,
        },
      },
    )

    validate_response!(response)

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
      total_duration: data['total_duration'],
    }
  end
end

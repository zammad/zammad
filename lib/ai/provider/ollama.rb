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

  # Input token limits (context windows) of the supported embedding models. These are small for
  # self-hosted models, so chunks must be sized against them (see Service::AI::VectorDB::Content::Chunks).
  EMBEDDING_INPUT_LIMITS = {
    'all-minilm'        => 256,
    'nomic-embed-text'  => 2048,
    'mxbai-embed-large' => 512,
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
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl: true,
        json:       true,
        log:        {
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
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl: true,
        json:       true,
      },
    )

    data = validate_response!(response)
    # /api/embed returns one vector per input as an array; #embed/#bulk_embed use it directly. Do
    # not collapse to the first vector — that drops the rest of a batch.
    data['response']['embeddings']
  end

  def self.ping!(config)
    response = UserAgent.get(
      config[:url],
      {},
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl: true,
        log:        {
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

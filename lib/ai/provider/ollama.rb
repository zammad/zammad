# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::Ollama < AI::Provider
  include AI::Provider::Concerns::HasConfigurableModel
  include AI::Provider::Concerns::ListsModels

  # The capabilities Ollama reports in /api/tags, mapped to the normalized ones. Everything else
  # it lists (tools, thinking, insert) says nothing about what the model can be used for here.
  REPORTED_CAPABILITIES = {
    'completion' => :chat,
    'embedding'  => :embedding,
    'vision'     => :vision,
  }.freeze

  DEFAULT_OPTIONS = {
    model:       'mistral-small3.2',
    temperature: 0.0,
  }.freeze

  RECOMMENDED_EMBEDDING_MODEL = 'bge-m3'.freeze

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
        log:        log_options,
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
        model: embedding_model!,
        input: input,
      },
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl: true,
        json:       true,
        log:        log_options,
      },
    )

    data = validate_response!(response)

    # /api/embed returns one vector per input as an array; #embed/#bulk_embed uses it directly.
    #   Do not collapse to the first vector, as that drops the rest of the batch.
    #   The response may have a top-level `embeddings` key in newer Ollama versions.
    data.dig('response', 'embeddings') || data['embeddings']
  end

  def self.supports_embeddings?
    true
  end

  # The catalogue is whatever the admin pulled: `ollama pull` adds a model in seconds, and the
  # dialog should see it without waiting out the listing cache of a hosted vendor.
  def self.volatile_model_listing?
    true
  end

  def self.recommended_embedding_model
    RECOMMENDED_EMBEDDING_MODEL
  end

  def self.ping!(config, related_object: nil)
    response = UserAgent.get(
      config[:url],
      {},
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl: true,
        log:        log_options(only_on_error: true, related_object:),
      },
    )

    validate_response!(response)

    nil
  end

  def self.models(config, related_object: nil)
    response = model_list_response("#{config[:url]}/api/tags", related_object:)

    data = validate_response!(response)

    # `model` is the pullable name including the tag; `name` is its alias in older versions.
    normalize_models(model_list_entries!(data, 'models'), 'model', 'name') do |entry, id|
      # An endpoint too old to report them answers with something else entirely, or not at all.
      details = entry['details']
      details = {} if !details.is_a?(Hash)

      model_descriptor(
        id:,
        capabilities:          reported_capabilities(entry['capabilities']),
        # Both sizes survive for an embedding model only; model_descriptor applies that rule
        # against the capabilities it settles on, heuristics included.
        embedding_input_limit: details['context_length'],
        embedding_size:        details['embedding_length'],
      )
    end
  end

  def self.reported_capabilities(capabilities)
    return nil if !capabilities.is_a?(Array)

    capabilities.filter_map { |capability| REPORTED_CAPABILITIES[capability] }
  end
  private_class_method :reported_capabilities

  # What Ollama itself knows about one pulled model: /api/show carries the embedding and context
  # lengths in model_info, prefixed with the model's architecture ('bert.embedding_length',
  # 'llama.context_length'). A metadata read like the model list, so it gets the same short
  # timeouts and quiet logging.
  def self.embedding_model_metadata(config, model, related_object: nil)
    response = UserAgent.post(
      "#{config[:url]}/api/show",
      { model: },
      {
        **MODEL_LIST_TIMEOUT_OPTIONS,
        verify_ssl: true,
        json:       true,
        log:        log_options(only_on_error: true, related_object:),
      },
    )

    data = validate_response!(response)
    data = {} if !data.is_a?(Hash)

    # An endpoint too old to serve model_info answers with something else entirely.
    info = data['model_info']
    info = {} if !info.is_a?(Hash)

    {
      embedding_size:        integer_value(model_info_value(info, 'embedding_length')),
      embedding_input_limit: integer_value(model_info_value(info, 'context_length')),
    }.compact
  end

  # The value under the architecture prefixed key, without having to know the architecture.
  def self.model_info_value(info, suffix)
    info.find { |key, _| key.to_s.end_with?(".#{suffix}") }&.last
  end
  private_class_method :model_info_value

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

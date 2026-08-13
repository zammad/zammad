# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::Mistral < AI::Provider
  include AI::Provider::Concerns::HandlesOpenAIMessages
  include AI::Provider::Concerns::HasConfigurableModel
  include AI::Provider::Concerns::ListsModels

  MISTRAL_API_BASE_URL = 'https://api.mistral.ai/v1'.freeze

  DEFAULT_OPTIONS = {
    temperature: 0.1,
    model:       'mistral-large-2512',
  }.freeze

  RECOMMENDED_EMBEDDING_MODEL = 'mistral-embed'.freeze

  def self.supports_embeddings?
    true
  end

  def self.recommended_embedding_model
    RECOMMENDED_EMBEDDING_MODEL
  end

  def self.ping!(config, related_object: nil)
    response = UserAgent.get(
      "#{MISTRAL_API_BASE_URL}/models",
      {},
      {
        **REQUEST_TIMEOUT_OPTIONS,
        verify_ssl:   true,
        bearer_token: config[:token],
        json:         true,
        log:          log_options(only_on_error: true, related_object:),
      },
    )

    validate_response!(response)

    nil
  end

  # Same endpoint as ping!, but its own request: ping! only has to reach the endpoint and must
  # not depend on the payload shape.
  def self.models(config, related_object: nil)
    response = model_list_response("#{MISTRAL_API_BASE_URL}/models", related_object:, bearer_token: config[:token])

    data = validate_response!(response)

    normalize_models(dedupe_aliases(model_list_entries!(data)), 'id') do |entry, id|
      model_descriptor(
        id:,
        capabilities:          reported_capabilities(entry['capabilities']),
        embedding_input_limit: entry['max_context_length'],
      )
    end
  end

  # Mistral lists every alias of a model as a full entry of its own ('mistral-medium',
  # 'mistral-medium-latest', 'mistral-medium-3', ... - up to eight ids for one model), which
  # would fill the dropdown with duplicates. One entry per alias group survives: the one with
  # the shortest id, which is the plain name an admin knows ('mistral-embed') and the one the
  # embedding recommendation points at.
  def self.dedupe_aliases(entries)
    entries
      .group_by { |entry| alias_group(entry) }
      .values
      .map { |group| group.min_by { |entry| [entry['id'].to_s.length, entry['id'].to_s] } }
  end
  private_class_method :dedupe_aliases

  # The complete set of ids an entry belongs to, the same for every member of the group.
  def self.alias_group(entry)
    aliases = entry['aliases']
    aliases = [] if !aliases.is_a?(Array)

    [entry['id'].to_s, *aliases.grep(String)].sort
  end
  private_class_method :alias_group

  # Mistral flags chat and vision, but has no flag for embedding models - those report no
  # capability at all and therefore fall back to the id heuristics.
  def self.reported_capabilities(capabilities)
    return nil if !capabilities.is_a?(Hash)

    result = []
    result << :chat   if capabilities['completion_chat']
    result << :vision if capabilities['vision']
    result
  end
  private_class_method :reported_capabilities

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
        log:          log_options,
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
        model: embedding_model!,
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

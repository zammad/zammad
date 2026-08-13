# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider::CustomOpenAI < AI::Provider
  include AI::Provider::Concerns::HandlesOpenAIMessages
  include AI::Provider::Concerns::HasConfigurableModel
  include AI::Provider::Concerns::HasModelsWithoutTemperatureFallback
  include AI::Provider::Concerns::ListsModels

  DEFAULT_OPTIONS = {
    temperature:                0.1,
    models_without_temperature: ['gpt-5']
  }.freeze

  # An OpenAI compatible endpoint does not have to implement the model list. These answers mean
  # "no list here" rather than a broken configuration, so they yield an empty list and let the
  # dialog fall back to the plain model text field.
  MODEL_LIST_UNSUPPORTED_CODES = [404, 405, 501].freeze

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

  def self.supports_embeddings?
    true
  end

  # The catalogue is whatever the admin deployed: a vLLM or LM Studio serves a new model after a
  # restart, and the dialog should see it without waiting out the listing cache of a hosted
  # vendor.
  def self.volatile_model_listing?
    true
  end

  def embeddings(input:)
    request_options = {
      **REQUEST_TIMEOUT_OPTIONS,
      verify_ssl: true,
      json:       true,
      log:        log_options,
    }

    # Token is optional since target host might not require authentication
    request_options[:bearer_token] = config[:token] if config[:token].present?

    response = UserAgent.post(
      "#{config[:url]}/embeddings",
      {
        # No recommendation to fall back to either: the model is whatever the admin deployed there.
        model: embedding_model!,
        input: input,
      },
      request_options,
    )

    data = validate_response!(response)

    # A compatible endpoint can answer 200 with a shape of its own making; that has to surface
    # as the mapped provider error, not as an internal one (same tolerance as the model list).
    entries = data.is_a?(Hash) ? data['data'] : nil
    raise AI::Provider::ResponseError, __('The response could not be processed.') if !entries.is_a?(Array)

    entries.pluck('embedding')
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

    evaluate_temperature_probe!(response)
  rescue CheckTemperatureSupportError
    raise
  rescue => e
    raise CheckTemperatureSupportError, e.message
  end

  def self.models(config, related_object: nil)
    # Token is optional since target host might not require authentication
    auth_options = config[:token].present? ? { bearer_token: config[:token] } : {}

    response = model_list_response("#{config[:url]}/models", related_object:, **auth_options)

    return [] if MODEL_LIST_UNSUPPORTED_CODES.include?(response.code.to_i)

    data = validate_response!(response)

    # Same tolerance for an endpoint that answers with something other than a model list; only
    # ids are guaranteed, so the capabilities come from the heuristics.
    normalize_models(model_list_entries(data) || [], 'id') do |_entry, id|
      model_descriptor(id:)
    end
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

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  include Mixin::RequiredSubPaths
  include AI::Provider::Concerns::HandlesResponse

  DEFAULT_OPTIONS = {}.freeze

  # Known defaults of the common embedding models, shared across the providers: what a model is
  # called does not depend on where it is served, so 'bge-m3' behind a custom OpenAI compatible
  # endpoint resolves the same as behind Ollama. Read through known_embedding_default only.
  EMBEDDING_SIZES = {
    'all-minilm'             => 384,
    'bge-m3'                 => 1024,
    'codestral-embed'        => 1536,
    'codestral-embed-2505'   => 1536,
    'mistral-embed'          => 1024,
    'mistral-embed-2312'     => 1024,
    'mxbai-embed-large'      => 1024,
    'nomic-embed-text'       => 768,
    'text-embedding-3-large' => 3072,
    'text-embedding-3-small' => 1536,
    'text-embedding-ada-002' => 1536,
  }.freeze

  # Input token limits (context windows) of the same models. These are small for the self-hosted
  # ones, so chunks must be sized against them (see Service::AI::VectorDB::Content::Chunks).
  EMBEDDING_INPUT_LIMITS = {
    'all-minilm'             => 256,
    'bge-m3'                 => 8192,
    'codestral-embed'        => 8192,
    'codestral-embed-2505'   => 8192,
    'mistral-embed'          => 8192,
    'mistral-embed-2312'     => 8192,
    'mxbai-embed-large'      => 512,
    'nomic-embed-text'       => 2048,
    'text-embedding-3-large' => 8191,
    'text-embedding-3-small' => 8191,
    'text-embedding-ada-002' => 8191,
  }.freeze

  # Conservative input-token limit for an embedding model not listed in EMBEDDING_INPUT_LIMITS —
  # favours safety (smaller chunks that fit small-context models) over granularity.
  DEFAULT_EMBEDDING_INPUT_LIMIT = 512

  # AI inference is slow; provide dedicated timeout knobs so admins can extend them for large prompts,
  # reasoning models, or slow self-hosted endpoints without raising the global HTTP timeouts.
  REQUEST_TIMEOUT_OPTIONS = {
    read_timeout:  ENV.fetch('ZAMMAD_HTTP_AI_READ_TIMEOUT', 300).to_i,
    total_timeout: ENV.fetch('ZAMMAD_HTTP_AI_TOTAL_TIMEOUT', 300).to_i,
  }.freeze

  attr_accessor :config, :options, :response_metadata

  # @param related_object [ApplicationModel, NilClass] what the HTTP logs of this instance point
  #   back at, normally the AI::ProviderConnection that built it.
  attr_reader :related_object

  def initialize(config: {}, options: {}, related_object: nil)
    @config         = config.presence || {}
    @related_object = related_object

    options = options.deep_symbolize_keys

    # .present?: a blank '' from a cleared config field must not override provider defaults.
    if @config[:model].present? && !options[:model]
      options[:model] = @config[:model]
    end

    if @config[:embedding_model].present? && !options[:embedding_model]
      options[:embedding_model] = @config[:embedding_model]
    end

    if @config[:embedding_input_limit].present? && !options[:embedding_input_limit]
      options[:embedding_input_limit] = @config[:embedding_input_limit]
    end

    @options = self.class::DEFAULT_OPTIONS.merge(options.compact)

    @response_metadata = {}
  end

  # HTTP log options for a request of this provider, attributing the log to the related object.
  def log_options(only_on_error: false)
    self.class.log_options(only_on_error:, related_object:)
  end

  class << self
    # The class level checks know no connection when one is created, but do when an existing one is
    # edited - hence the optional related object rather than none at all.
    def log_options(only_on_error: false, related_object: nil)
      {
        facility:          'AI::Provider',
        log_only_on_error: only_on_error,
        related_object:,
      }.compact
    end

    # The adapter for a provider key, or nil for anything that is not one. The namespace holds
    # more than adapters (the errors, the concerns), and a key resolving to one of those would
    # otherwise pass for a provider and only fail once a request is made against it.
    #
    # @return [Class, NilClass] the adapter class
    def by_name(name)
      klass = "AI::Provider::#{name.classify}".safe_constantize
      return nil if !klass.is_a?(Class) || !(klass < AI::Provider)

      klass
    end

    # A provider validates its config with exactly one request when a connection is saved:
    # either here, or in check_temperature_support! for providers that talk to the endpoint
    # there anyway. Hence the no-op default — overriding both would ping twice.
    def ping!(_config, related_object: nil)
      nil
    end

    # Detects whether the configured model accepts the temperature parameter. Providers that
    # answer this with a real request also validate the config (they raise
    # CheckTemperatureSupportError for anything but an unsupported temperature) and therefore
    # do not implement ping!.
    def check_temperature_support!(_config, related_object: nil)
      true
    end

    # True when the endpoint refused nothing but the temperature parameter. Any other failure is
    # a config problem (wrong token, wrong URL, unreachable host) that has to surface with the
    # mapped provider message, so the body is never trusted: on a transport error it is nil, and
    # a proxy in between may answer with HTML.
    def temperature_unsupported?(response)
      data  = JSON.parse(response.body.to_s)
      data  = data.pop if data.is_a?(Array) # some endpoints answer with an array of errors
      error = data.is_a?(Hash) ? data['error'] : nil
      return false if !error.is_a?(Hash)

      error.values_at('type', 'param', 'code') == %w[invalid_request_error temperature unsupported_value]
    rescue JSON::ParserError
      false
    end

    # Shared tail of check_temperature_support! for providers that probe the endpoint with a real
    # request: true when it succeeds outright, false when it fails solely on the temperature
    # parameter, otherwise raises with the mapped provider message.
    def evaluate_temperature_probe!(response)
      return true if response.success?
      return false if temperature_unsupported?(response)

      # Not a temperature quirk but a broken config: raise with the mapped provider message.
      validate_response!(response)

      true
    rescue => e
      raise CheckTemperatureSupportError, e.message
    end

    # The model a connection that names none runs on: what the dialog pre-selects, and what
    # AI::Provider resolves to at request time via DEFAULT_OPTIONS.
    #
    # Read through here rather than off the option hash: the dialog learns the default from the
    # model listing endpoint (see Service::AI::ProviderConnection::ListModels), and nothing outside
    # the adapters should have to know that `options` is where it lives.
    #
    # @return [String, NilClass] the default model, nil for a provider without one
    def default_model
      self::DEFAULT_OPTIONS[:model]
    end

    # True when embed() is implemented; filters the Semantic Search connection dropdown.
    def supports_embeddings?
      false
    end

    # The embedding model to recommend for this provider: what the connection dialog pre-selects,
    # and what a connection that relied on the former silent fallback was backfilled with.
    #
    # Deliberately not part of DEFAULT_OPTIONS: that hash feeds `options`, which is what used to
    # resolve an embedding model at request time - invisible in the admin UI and moving under the
    # admin's feet whenever the default was bumped. The model actually used is always the one
    # persisted in config[:embedding_model].
    #
    # @return [String, NilClass] the recommended model, nil for a provider with no sensible one
    def recommended_embedding_model
      nil
    end

    # The embedding model of a provider whose model is not part of the connection config at all:
    # Zammad AI serves a fixed one, so the dialog shows no field for it and the connection stores
    # nothing. The only remaining implicit resolution, and one an admin cannot influence anyway.
    #
    # @return [String, NilClass] the fixed model, nil for a provider whose model is configured
    def embedding_model_fallback
      nil
    end

    # The value the shared table of known embedding model defaults holds for a model
    # (EMBEDDING_SIZES, EMBEDDING_INPUT_LIMITS).
    #
    # Everything reading those tables has to come through here, because a model name does not
    # always match a key verbatim: Ollama identifies a model by name and tag ('bge-m3:latest'),
    # while the tables are keyed by name alone. A miss is not harmless - it fails vector table
    # creation (Service::AI::VectorDB::CreateTable) and silently shrinks the chunks an embedding
    # model is fed (#embedding_input_limit).
    #
    # @return [Integer, NilClass] the known default, nil when the table has none for the model
    def known_embedding_default(table, model)
      model = model.to_s
      return nil if model.blank?

      defaults = const_get(table)
      value    = defaults[model] || defaults[model.split(':').first]

      value if value.is_a?(Integer)
    end

    # Metadata the provider serves about one specific model (Ollama's /api/show). The default is
    # knowing nothing, so a caller moves on to the shared table of known defaults. Deliberately
    # not a place to repeat the model listing: everything a listing carries already travels in
    # its descriptors, in one request (see
    # Service::AI::ProviderConnection::ResolveEmbeddingMetadata).
    #
    # @return [Hash] embedding_size and/or embedding_input_limit - only the reported ones
    def embedding_model_metadata(_config, _model, related_object: nil)
      {}
    end

    # True when the endpoint can enumerate its models, so the connection dialog can offer a
    # dropdown. A provider without a model list keeps the plain model text field (Azure AI's
    # deployment based endpoints, Zammad AI).
    def supports_model_listing?
      false
    end

    # True when the model catalogue is under the admin's own control and can change any moment
    # (a self-hosted Ollama pulls a model in seconds, a custom endpoint deploys at will), so a
    # cached listing goes stale much faster than the fixed catalogue of a hosted vendor. Decides
    # how long Service::AI::ProviderConnection::ListModels may cache the listing.
    def volatile_model_listing?
      false
    end

    # The models the endpoint offers for the given config, normalized so a caller does not have
    # to know any provider specifics:
    #
    #   { id:, capabilities: [:chat, :embedding, :vision], embedding_input_limit:,
    #     embedding_size: }
    #
    # Fields the provider does not report stay nil instead of being guessed. Only called for a
    # provider that answers supports_model_listing? with true; a listing failure surfaces as a
    # RequestError/ResponseError like any other provider request (see Concerns::ListsModels).
    #
    # @return [Array<Hash>] the normalized model descriptors
    def models(_config, related_object: nil)
      raise NotImplementedError
    end
  end

  def ask(prompt_system:, prompt_user:, prompt_image: nil)
    result = chat(prompt_system:, prompt_user:, prompt_image:)

    return result if !options[:json_response]

    begin
      begin
        JSON.parse(result)
      rescue JSON::ParserError
        # If initial parsing fails, try to strip markdown code blocks and try again.
        cleaned_result = transform_json_response(result)
        JSON.parse(cleaned_result)
      end
    rescue => e
      Rails.logger.error "Unable to parse JSON response: #{e.inspect}"
      Rails.logger.error "Response: #{result}"

      raise OutputFormatError, __('The response could not be processed.')
    end
  end

  # Fetches the embedding for a single input. For multiple inputs, use bulk_embed.
  #
  # @param input [String] the input to embed
  # @return [Array<Numeric>] the embedding vector for the input
  def embed(input:)
    embeddings(input:).first
  end

  # Fetches embeddings for multiple inputs.
  #
  # @param input [Array<String>] the inputs to embed
  # @return [Array<Array<Numeric>>] an array of embedding vectors corresponding to the inputs
  def bulk_embed(input:)
    embeddings(input: Array(input))
  end

  # The embedding model to embed with: the configured one, or the fixed one of a provider whose
  # model is not configurable at all.
  #
  # @return [String, NilClass] the embedding model
  def embedding_model
    options[:embedding_model].presence || self.class.embedding_model_fallback
  end

  # Same, for the embedding request itself. Every adapter's embeddings() asks for it here, so that
  # a missing one fails with the same message everywhere instead of each provider quietly embedding
  # against whatever its own default or its endpoint's default happens to be - the model behind a
  # stored vector has to be the one the admin can see in the dialog.
  #
  # @return [String] the embedding model
  def embedding_model!
    return embedding_model if embedding_model.present?

    raise RequestError, __('Missing embedding model in the provider configuration')
  end

  # Maximum number of input tokens the configured embedding model accepts. Used to size chunks so
  # no chunk overruns the model (see Service::AI::VectorDB::Content::Chunks). Unknown models fall back conservatively.
  #
  # The configured limit comes out of a jsonb config, which keeps whatever was written into it -
  # down to a string ('8192') the chunk budget cannot be compared against, or a number that is no
  # budget at all, which the chunker raises on. AI::ProviderConnection rejects those on save, but a
  # config predating that validation is still out there, so anything but a positive whole number
  # falls through to what is known about the model (mirrors CreateTable's handling of the size).
  #
  # @return [Integer] the model's input token limit
  def embedding_input_limit
    configured = Integer(options[:embedding_input_limit].to_s, exception: false)
    return configured if configured&.positive?

    self.class.known_embedding_default(:EMBEDDING_INPUT_LIMITS, embedding_model) || DEFAULT_EMBEDDING_INPUT_LIMIT
  end

  def metadata
    {
      provider:    self.class.name,
      temperature: options[:temperature],
    }.merge(specific_metadata).merge(@response_metadata)
  end

  private

  def model_supports_temperature?
    config[:model_temperature_support] != false
  end

  def transform_json_response(result)
    return result if result.blank?

    result = result.strip.sub(%r{\A`{1,3}(?:json)?\s*(.*?)\s*`{1,3}\z}m, '\1').strip

    # LLMs often return JSON with literal control characters (newlines, tabs, etc.)
    # inside string values, which is invalid per the JSON spec.
    # The regex matches JSON string literals (including ones with literal control chars),
    # then replaces only the problematic characters inside them.
    result.gsub(%r{"(?:[^"\\]|\\.|\p{Cc})*"}m) do |json_string|
      inner = json_string[1..-2]
      inner = inner.gsub("\r\n", '\\n')
                   .gsub("\r", '\\r')
                   .gsub("\n", '\\n')
                   .gsub("\t", '\\t')
      "\"#{inner}\""
    end
  end

  def specific_metadata
    {}
  end

  def extract_response_metadata(_data)
    @response_metadata = {}
  end

  def chat(prompt_system:, prompt_user:, prompt_image:)
    raise 'not implemented'
  end

  def embeddings(input:)
    raise 'not implemented'
  end

  class RequestError < StandardError; end
  class ResponseError < StandardError; end
  class OutputFormatError < ResponseError; end
  class CheckTemperatureSupportError < ResponseError; end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  include Mixin::RequiredSubPaths
  include AI::Provider::Concerns::HandlesResponse

  DEFAULT_OPTIONS = {}.freeze

  EMBEDDING_SIZES = {}.freeze

  EMBEDDING_INPUT_LIMITS = {}.freeze

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

  def initialize(config: {}, options: {})
    @config = config.presence || Setting.get('ai_provider_config')

    if @config[:model] && !options[:model]
      options[:model] = @config[:model]
    end

    if @config[:embedding_model] && !options[:embedding_model]
      options[:embedding_model] = @config[:embedding_model]
    end

    @options = self.class::DEFAULT_OPTIONS.merge(options.compact.deep_symbolize_keys)

    @response_metadata = {}
  end

  class << self
    def by_name(name)
      "AI::Provider::#{name.classify}".safe_constantize
    end

    def by_config(config)
      provider_name = config&.dig(:provider)
      return if provider_name.blank?

      by_name(provider_name)
    end

    def current
      return nil if !Setting.get('ai_provider')

      by_config(Setting.get('ai_provider_config'))
    end

    def ping!(_config)
      raise 'not implemented'
    end

    def check_temperature_support!(_config)
      true
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

  # Maximum number of input tokens the configured embedding model accepts. Used to size chunks so
  # no chunk overruns the model (see Service::AI::VectorDB::Content::Chunks). Unknown models fall back conservatively.
  #
  # @return [Integer] the model's input token limit
  def embedding_input_limit
    self.class::EMBEDDING_INPUT_LIMITS.fetch(options[:embedding_model], DEFAULT_EMBEDDING_INPUT_LIMIT)
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

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  include Mixin::RequiredSubPaths
  include AI::Provider::Concerns::HandlesResponse

  DEFAULT_OPTIONS = {}.freeze

  EMBEDDING_SIZES = {}.freeze

  attr_accessor :config, :options, :response_metadata

  def initialize(config: {}, options: {})
    @config = config.presence || Setting.get('ai_provider_config')

    if @config[:model] && !options[:model]
      options[:model] = @config[:model]
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
  end

  def ask(prompt_system:, prompt_user:)
    result = chat(prompt_system:, prompt_user:)

    return result if !options[:json_response]

    begin
      JSON.parse(result)
    rescue => e
      Rails.logger.error "Unable to parse JSON response: #{e.inspect}"
      Rails.logger.error "Response: #{result}"

      raise OutputFormatError, __('The response could not be processed.')
    end
  end

  def embed(input:)
    embeddings(input:)
  end

  def metadata
    {
      provider:    self.class.name,
      temperature: options[:temperature],
    }.merge(specific_metadata).merge(@response_metadata)
  end

  private

  def specific_metadata
    {}
  end

  def extract_response_metadata(_data)
    @response_metadata = {}
  end

  def chat(prompt_system:, prompt_user:)
    raise 'not implemented'
  end

  def embeddings(input:)
    raise 'not implemented'
  end

  class RequestError < StandardError; end
  class ResponseError < StandardError; end
  class OutputFormatError < ResponseError; end
end

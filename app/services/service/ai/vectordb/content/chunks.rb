# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB::Content
  class Chunks < Service::Base
    attr_reader :content, :content_meta_headers, :strategy, :model_max_tokens, :options

    # @param model_max_tokens [Integer, nil] the embedding model's hard input limit (a ceiling on
    #   the chunk size, independent of the strategy). nil = no ceiling.
    def initialize(content:, content_meta_headers: [], strategy: :sentence, model_max_tokens: nil, options: {})
      @content              = content
      @content_meta_headers = content_meta_headers
      @strategy             = strategy
      @model_max_tokens     = model_max_tokens
      @options              = options
    end

    def execute
      klass = strategy_class
      raise ArgumentError, "Unknown chunking strategy: #{strategy.inspect}" if klass.nil?

      klass.new(content:, content_meta_headers:, model_max_tokens:, options:).execute
    end

    private

    def strategy_class
      raise ArgumentError, "Chunking strategy not allowed: #{strategy.inspect}" if strategy.to_s.start_with?('base')

      "Service::AI::VectorDB::Content::Chunks::Strategy::#{strategy.to_s.classify}".safe_constantize
    end
  end
end

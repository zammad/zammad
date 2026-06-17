# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB::Content
  class Chunks < Service::Base
    attr_reader :content, :content_meta_headers, :strategy, :options

    def initialize(content:, content_meta_headers: [], strategy: :sentence, options: {})
      @content              = content
      @content_meta_headers = content_meta_headers
      @strategy             = strategy
      @options              = options
    end

    def execute
      klass = strategy_class
      raise ArgumentError, "Unknown chunking strategy: #{strategy.inspect}" if klass.nil?

      klass.new(content:, content_meta_headers:, options:).execute
    end

    private

    def strategy_class
      "Service::AI::VectorDB::Content::Chunks::Strategy::#{strategy.to_s.classify}".safe_constantize
    end
  end
end

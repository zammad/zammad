# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB::Content::Chunks::Strategy
  class Sentence < BaseText
    def execute
      meta_text   = content_meta_headers.join("\n")
      meta_tokens = self.class.estimate_tokens(meta_text)
      budget      = resolved_max_tokens - meta_tokens
      raise ArgumentError, 'content_meta_headers exceed max_tokens_per_chunk' if budget <= 0

      safe_budget = model_max_tokens ? (budget * self.class::SAFETY_FRACTION).floor : budget
      chunks = enforce_max_tokens(build_chunks(split_sentences(content), safe_budget, budget), budget)

      chunks.map { |chunk| format_chunk(meta_text, chunk) }
    end

    private

    def split_sentences(text)
      text.split(%r{(?<=[.!?:])\s+}).map(&:strip).reject(&:empty?)
    end

    def enforce_max_tokens(chunks, limit)
      chunks.flat_map do |chunk|
        next [chunk] if self.class.estimate_tokens(chunk) <= limit

        split_by_characters(chunk, limit)
      end
    end

    def build_chunks(sentences, budget, hard_limit = budget)
      overlap_budget = [resolved_overlap_tokens, budget].min
      chunks = []
      current = []
      current_tokens = 0

      sentences.flat_map { |s| split_oversized(s, hard_limit) }.each do |sentence|
        s_tokens = self.class.estimate_tokens(sentence)

        if current.any? && current_tokens + s_tokens > budget
          chunks << join_sentences(current)

          # Overlap budget is capped to leave room for the incoming sentence,
          # ensuring the new chunk never exceeds the limit.
          available = [overlap_budget, budget - s_tokens].min
          overlap = trailing_overlap(current, available)
          current = overlap
          current_tokens = self.class.estimate_tokens(join_sentences(overlap))
        end

        current << sentence
        current_tokens += s_tokens
      end

      chunks << join_sentences(current) if current.any?
      chunks
    end

    def trailing_overlap(sentences, budget)
      result = []
      tokens = 0
      sentences.reverse_each do |s|
        t = self.class.estimate_tokens(s)
        break if tokens + t > budget

        result.unshift(s)
        tokens += t
      end
      result
    end

    def join_sentences(sentences)
      sentences.join(' ')
    end
  end
end

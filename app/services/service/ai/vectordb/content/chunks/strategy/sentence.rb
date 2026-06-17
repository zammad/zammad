# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::VectorDB::Content::Chunks::Strategy::Sentence < Service::AI::VectorDB::Content::Chunks::Strategy::Base
  DEFAULT_MAX_TOKENS = 512
  DEFAULT_OVERLAP    = 0.1

  def execute
    max_tokens   = options.fetch(:max_tokens_per_chunk, DEFAULT_MAX_TOKENS)
    overlap_rate = options.fetch(:overlap_amount, DEFAULT_OVERLAP).clamp(0.0, 0.5)

    meta_text   = content_meta_headers.join("\n")
    meta_tokens = self.class.estimate_tokens(meta_text)
    budget      = max_tokens - meta_tokens
    raise ArgumentError, 'content_meta_headers exceed max_tokens_per_chunk' if budget <= 0

    sentences = split_sentences(content)
    chunks    = build_chunks(sentences, budget, overlap_rate)

    chunks.map { |chunk| format_chunk(meta_text, chunk) }
  end

  private

  def split_sentences(text)
    text.split(%r{(?<=[.!?:])\s+}).map(&:strip).reject(&:empty?)
  end

  def build_chunks(sentences, budget, overlap_rate)
    overlap_budget = (budget * overlap_rate).floor
    chunks = []
    current = []
    current_tokens = 0

    sentences.each do |sentence|
      s_tokens = self.class.estimate_tokens(sentence)
      raise ArgumentError, 'single sentence exceeds chunk token budget', sentence if s_tokens > budget

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

  def format_chunk(meta_text, chunk_text)
    return chunk_text if meta_text.empty?

    "#{meta_text}\n\n#{chunk_text}"
  end
end

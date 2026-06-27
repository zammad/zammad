# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Deterministic, boundary-aware chunking. Splits on the largest natural
# boundary that fits (paragraph -> sentence -> word -> grapheme) and packs the pieces into
# token-sized windows with overlap, so no chunk exceeds the embedding model's input limit. Token
# counts are approximated without a tokenizer dependency (Strategy::Base.estimate_tokens), which
# stays robust for no-space scripts (CJK/Thai) where a whole paragraph is otherwise one "word".
#
# Compared to Strategy::Sentence this additionally recognises CJK terminators and paragraph breaks,
# and re-measures every emitted chunk against the hard limit. Max chunk size and overlap come from
# Strategy::Base (strategy default, capped by the model's ceiling).
module Service::AI::VectorDB::Content::Chunks::Strategy
  class Recursive < BaseText
    # Packing target (clamped below the resolved max), in tokens.
    DEFAULT_TARGET_TOKENS = 500

    # Sentence boundaries: Latin terminators followed by whitespace, plus CJK terminators (which are
    # not followed by a space).
    SENTENCE_BOUNDARY = %r{(?<=[.!?])\s+|(?<=[。！？])}

    # @return [Array<String>] the content split into chunks (empty for blank content), each prefixed
    #   with the meta headers so every embedded vector carries the document's context.
    def execute
      target_tokens = options.fetch(:target_tokens, DEFAULT_TARGET_TOKENS)

      # Reserve room for the meta headers prepended to every chunk, so chunk body + headers never
      # overruns the resolved per-chunk size.
      meta_text   = content_meta_headers.join("\n")
      meta_tokens = self.class.estimate_tokens(meta_text)
      @max_tokens = resolved_max_tokens - meta_tokens
      raise ArgumentError, 'content_meta_headers exceed max_tokens_per_chunk' if @max_tokens <= 0

      @overlap_tokens = [resolved_overlap_tokens, @max_tokens / 2].min
      # A chunk is at most one packed window plus an overlap seed; keep that sum within the budget,
      # and within the safety fraction so an undercounted estimate still fits the hard limit.
      safe_target    = model_max_tokens ? [(@max_tokens * SAFETY_FRACTION).floor, @max_tokens - @overlap_tokens].min : @max_tokens - @overlap_tokens
      @target_tokens = target_tokens.clamp(1, [safe_target, 1].max)

      units = atomic_units
      return [] if units.empty?

      enforce_max_tokens(pack(units)).map { |chunk| format_chunk(meta_text, chunk) }
    end

    private

    # Sentence-level units, with any oversized sentence hard-split (by word, then by grapheme) so
    # that no single unit can exceed the target size.
    def atomic_units
      content.to_s
        .split(%r{\n{2,}})
        .flat_map { |paragraph| paragraph.split(SENTENCE_BOUNDARY) }
        .flat_map { |sentence| split_oversized(sentence, @target_tokens) }
        .map(&:strip)
        .reject(&:empty?)
    end

    def pack(units)
      chunks  = []
      current = []
      tokens  = 0

      units.each do |unit|
        unit_tokens = self.class.estimate_tokens(unit)

        if tokens + unit_tokens > @target_tokens && current.any?
          chunks << current.join(' ')
          current, tokens = overlap_tail(current)
        end

        current << unit
        tokens  += unit_tokens
      end

      chunks << current.join(' ') if current.any?
      chunks
    end

    # Trailing units of the just-emitted chunk, totalling up to OVERLAP tokens, used to seed the next
    # chunk so context carries across the boundary.
    def overlap_tail(units)
      return [[], 0] if @overlap_tokens <= 0

      tail   = []
      tokens = 0
      units.reverse_each do |unit|
        unit_tokens = self.class.estimate_tokens(unit)
        break if tokens + unit_tokens > @overlap_tokens

        tail.unshift(unit)
        tokens += unit_tokens
      end

      [tail, tokens]
    end

    # Final safety guard: no emitted chunk body may exceed the budget. Packing targets a smaller
    # size, so this only fires for pathological input; such a chunk is split by grapheme.
    def enforce_max_tokens(chunks)
      chunks.flat_map do |chunk|
        self.class.estimate_tokens(chunk) <= @max_tokens ? [chunk] : split_by_characters(chunk, @target_tokens)
      end
    end
  end
end

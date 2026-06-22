# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared text-splitting helpers used by both Strategy::Sentence and Strategy::Recursive.
# All methods accept an explicit +limit+ (in tokens) so each strategy can drive them with its
# own budget (safe target, hard ceiling, etc.) without relying on instance-variable state.
class Service::AI::VectorDB::Content::Chunks::Strategy::BaseText < Service::AI::VectorDB::Content::Chunks::Strategy::Base
  private

  # Splits +text+ so that every returned piece fits within +limit+ tokens.
  # Tries word boundaries first; falls back to grapheme-cluster splitting for runs with no
  # whitespace (CJK, long URLs, hashes).
  def split_oversized(text, limit)
    return [text] if self.class.estimate_tokens(text) <= limit

    split_by_words(text, limit).flat_map do |piece|
      self.class.estimate_tokens(piece) <= limit ? [piece] : split_by_characters(piece, limit)
    end
  end

  def split_by_words(text, limit)
    words = text.split(%r{\s+}).reject(&:empty?)
    return [text] if words.empty?

    pack_pieces(words, ' ', limit)
  end

  # Last-resort split for a single oversized token (no-space script, a long URL or hash) that has
  # no whitespace boundary to fall back on.
  def split_by_characters(text, limit)
    pack_pieces(text.grapheme_clusters, '', limit)
  end

  # Greedily packs atomic items (words or characters) into pieces whose estimated token count stays
  # within +limit+. An item that alone exceeds the budget is emitted on its own.
  def pack_pieces(items, separator, limit)
    pieces  = []
    current = []
    tokens  = 0

    items.each do |item|
      item_tokens = self.class.estimate_tokens(item)

      if current.any? && tokens + item_tokens > limit
        pieces << current.join(separator)
        current = []
        tokens  = 0
      end

      current << item
      tokens  += item_tokens
    end

    pieces << current.join(separator) if current.any?
    pieces
  end

  def format_chunk(meta_text, chunk_text)
    return chunk_text if meta_text.empty?

    "#{meta_text}\n\n#{chunk_text}"
  end
end

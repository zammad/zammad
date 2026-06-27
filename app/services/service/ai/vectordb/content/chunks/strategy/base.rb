# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::VectorDB::Content::Chunks::Strategy::Base
  SUBWORD_LENGTH = 5

  # Default chunk size and overlap, in tokens. The strategy owns these (a caller may override via
  # options); the embedding model's input limit (model_max_tokens) is only a hard ceiling that caps
  # them — it does not drive the chunk size.
  DEFAULT_MAX_TOKENS     = 512
  DEFAULT_OVERLAP_TOKENS = 50

  # Fraction of the token budget used as the packing target. Kept below 1.0 because estimate_tokens
  # can undercount dense Latin text (compounded German, inflected Polish) by up to ~1.8×; staying at
  # 0.7 gives enough headroom while using more of the available context than 0.5 did.
  SAFETY_FRACTION = 0.7

  # Approximate the embedding-model token count without a tokenizer dependency: scan the text into
  # whitespace-free runs and size each by character density. Deliberately conservative (errs toward
  # over-counting) so it never undercounts the safety-critical cases (CJK, long digit/symbol blobs).
  def self.estimate_tokens(text)
    text.to_s.scan(%r{\p{L}+|\p{N}+|[^\p{L}\p{N}\s]+}).sum { |run| run_tokens(run) }
  end

  # Tokens for one whitespace-free run, calibrated against cl100k_base (text-embedding-3):
  def self.run_tokens(run)
    case run
    when %r{\A\p{Latin}+\z}            # Latin words ~4 chars/token (the OpenAI rule of thumb)
      run.length <= SUBWORD_LENGTH ? 1 : (run.length / 4.0).ceil
    when %r{\A\p{N}+\z}                # digit runs tokenize denser → /2
      run.length <= SUBWORD_LENGTH ? 1 : (run.length / 2.0).ceil
    else                               # non-Latin scripts (CJK/Cyrillic/Greek/Arabic/Thai) + symbols
      run.length                       # ~1 token per character (cl100k splits these near byte level)
    end
  end

  attr_reader :content, :content_meta_headers, :options, :model_max_tokens

  # @param model_max_tokens [Integer, nil] the embedding model's hard input limit. Only caps the
  #   chunk size; nil means "no ceiling" (use the strategy default / override as-is).
  def initialize(content:, content_meta_headers:, options:, model_max_tokens: nil)
    @content              = content
    @content_meta_headers = content_meta_headers
    @options              = options
    @model_max_tokens     = model_max_tokens
  end

  def execute
    raise NotImplementedError
  end

  private

  # The per-chunk size: the strategy default (caller-overridable via options[:max_tokens_per_chunk]),
  # capped by the model's hard ceiling when one is given. The strategy decides the size; the model
  # only sets an upper bound.
  def resolved_max_tokens
    [options.fetch(:max_tokens_per_chunk, self.class::DEFAULT_MAX_TOKENS), model_max_tokens].compact.min
  end

  # Absolute overlap (tokens) carried across chunk boundaries — a roughly fixed amount of context
  # (a sentence or two), never more than half a chunk.
  def resolved_overlap_tokens
    options.fetch(:overlap_tokens, self.class::DEFAULT_OVERLAP_TOKENS).clamp(0, resolved_max_tokens / 2)
  end
end

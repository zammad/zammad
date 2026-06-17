# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::VectorDB::Content::Chunks::Strategy::Base
  SUBWORD_LENGTH = 5

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

  attr_reader :content, :content_meta_headers, :options

  def initialize(content:, content_meta_headers:, options:)
    @content              = content
    @content_meta_headers = content_meta_headers
    @options              = options
  end

  def execute
    raise NotImplementedError
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Content::Chunks::Strategy::Sentence, :aggregate_failures do
  def chunk(text, headers: [], **opts)
    Service::AI::VectorDB::Content::Chunks.execute(content: text, content_meta_headers: headers, strategy: :sentence, options: opts)
  end

  def within_limit?(chunks, max_tokens)
    chunks.all? { |c| Service::AI::VectorDB::Content::Chunks::Strategy::Base.estimate_tokens(c) <= max_tokens }
  end

  it 'keeps short content as a single chunk' do
    expect(chunk('A short sentence.')).to eq(['A short sentence.'])
  end

  it 'splits on sentence boundaries' do
    chunks = chunk('First sentence. Second sentence.', max_tokens_per_chunk: 8, overlap_tokens: 0)

    expect(chunks).to eq(['First sentence.', 'Second sentence.'])
  end

  context 'with English content longer than the budget' do
    let(:sentences) { Array.new(20) { |i| "This is sentence number #{i}." } }
    let(:text)      { sentences.join(' ') }
    let(:chunks)    { chunk(text, max_tokens_per_chunk: 40, overlap_tokens: 8) }

    it 'splits into multiple chunks' do
      expect(chunks.length).to be > 1
    end

    it 'keeps every chunk within the token limit' do
      expect(within_limit?(chunks, 40)).to be(true)
    end

    it 'overlaps consecutive chunks for context continuity' do
      tail_words  = chunks.first.split.last(4)
      start_words = chunks.second.split.first(16)

      expect(start_words).to include(*tail_words)
    end
  end

  # Previously this raised ArgumentError. The sentence is 30 two-token words
  # (~60 tokens) with no terminator so split_sentences returns it as one unit.
  context 'when a single sentence exceeds the token budget' do
    # "ab0".."ab29": each word is "ab" (1 token) + digit (1 token) = 2 tokens → 60 tokens total.
    let(:text) { Array.new(30) { |i| "ab#{i}" }.join(' ') }

    it 'does not raise' do
      expect { chunk(text, max_tokens_per_chunk: 10, overlap_tokens: 0) }.not_to raise_error
    end

    it 'splits into multiple chunks' do
      expect(chunk(text, max_tokens_per_chunk: 10, overlap_tokens: 0).length).to be > 1
    end

    it 'keeps every chunk within the token limit' do
      expect(within_limit?(chunk(text, max_tokens_per_chunk: 10, overlap_tokens: 0), 10)).to be(true)
    end

    it 'preserves all words across the chunks' do
      chunks = chunk(text, max_tokens_per_chunk: 10, overlap_tokens: 0)

      expect(chunks.flat_map(&:split)).to match_array(text.split)
    end
  end

  # A single run of CJK characters has no whitespace, so split_by_words cannot
  # break it up — the strategy must fall through to character-level splitting.
  context 'when a sentence has no whitespace (CJK)' do
    # Each '中' is 1 token (non-Latin) → 60 tokens total with no space boundaries.
    let(:text) { '中' * 60 }

    it 'does not raise' do
      expect { chunk(text, max_tokens_per_chunk: 20, overlap_tokens: 0) }.not_to raise_error
    end

    it 'splits by characters into multiple chunks' do
      expect(chunk(text, max_tokens_per_chunk: 20, overlap_tokens: 0).length).to be > 1
    end

    it 'keeps every chunk within the token limit' do
      expect(within_limit?(chunk(text, max_tokens_per_chunk: 20, overlap_tokens: 0), 20)).to be(true)
    end
  end

  context 'with content_meta_headers' do
    let(:text)    { Array.new(10) { |i| "Sentence number #{i} of the body." }.join(' ') }
    let(:headers) { ['How to reset your password'] }
    let(:chunks)  { chunk(text, headers:, max_tokens_per_chunk: 40, overlap_tokens: 0) }

    it 'prepends the meta headers to every chunk' do
      expect(chunks).to all(start_with("How to reset your password\n\n"))
    end

    it 'keeps chunk body plus headers within the token limit' do
      expect(within_limit?(chunks, 40)).to be(true)
    end
  end
end

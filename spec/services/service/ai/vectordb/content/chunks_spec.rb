# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Content::Chunks do
  subject(:result) { described_class.execute(content:, content_meta_headers:, strategy:, model_max_tokens:, options:) }

  let(:content_meta_headers) { [] }
  let(:strategy)             { :sentence }
  let(:model_max_tokens)     { nil }
  let(:options)              { {} }

  # Each short sentence used in these tests is 3 tokens:
  #   one-word subject (1) + one-word verb (1) + period (1)
  # This makes chunking behaviour predictable for exact assertions.

  describe '#execute' do
    context 'when content fits within the default token limit' do
      let(:content) { 'Hello world. This is a test.' }

      it 'returns a single-element array containing the full content' do
        expect(result).to eq(['Hello world. This is a test.'])
      end
    end

    context 'when content exceeds the token limit' do
      # 3 tokens/sentence × 4 sentences = 12 tokens; budget 8 → 2 chunks of 2 sentences each
      let(:content) { 'Dogs run. Cats jump. Birds fly. Fish swim.' }
      let(:options) { { max_tokens_per_chunk: 8 } }

      it 'returns more than one chunk' do
        expect(result.length).to be > 1
      end

      it 'every chunk stays within the token limit' do
        expect(result).to all(satisfy { |chunk|
          described_class::Strategy::Sentence.estimate_tokens(chunk) <= 8
        })
      end
    end

    context 'when the model ceiling is below the strategy default' do
      let(:content)          { 'Dogs run. Cats jump. Birds fly. Fish swim.' }
      let(:model_max_tokens) { 8 }

      it 'caps chunks at the model ceiling rather than the strategy default', :aggregate_failures do
        expect(result.length).to be > 1
        expect(result).to all(satisfy { |chunk|
          described_class::Strategy::Base.estimate_tokens(chunk) <= 8
        })
      end
    end

    context 'when overlap is configured' do
      # 3 tokens/sentence; budget=8 fits 2 sentences per chunk;
      # overlap_tokens=4 fits exactly 1 sentence (3 tokens).
      let(:content) { 'Dogs run. Cats jump. Birds fly. Fish swim.' }
      let(:options) { { max_tokens_per_chunk: 8, overlap_tokens: 4 } }

      it 'carries the tail of each chunk into the next one' do
        expect(result).to eq([
                               'Dogs run. Cats jump.',
                               'Cats jump. Birds fly.',
                               'Birds fly. Fish swim.',
                             ])
      end
    end

    context 'when content meta headers are provided' do
      let(:content)              { 'Hello world.' }
      let(:content_meta_headers) { ['Category: Support', 'Language: English'] }

      it 'prepends the joined metadata lines to every chunk' do
        expect(result.first).to eq("Category: Support\nLanguage: English\n\nHello world.")
      end
    end

    context 'when content meta headers reduces the available token budget' do
      # "tag" = 1 meta text token; max=6 -> content budget=5;
      # each sentence is 3 tokens, so 3+3=6 would exceed 5 -> two separate chunks.
      let(:content)              { 'Dogs run. Cats jump.' }
      let(:content_meta_headers) { ['tag'] }
      let(:options)              { { max_tokens_per_chunk: 6 } }

      it 'splits content that would otherwise fit into a single chunk' do
        expect(result.length).to be >= 2
      end

      it 'keeps every chunk within the token limit including metadata' do
        expect(result).to all(satisfy { |chunk|
          described_class::Strategy::Sentence.estimate_tokens(chunk) <= 6
        })
      end
    end

    context 'when an unknown strategy is given' do
      let(:content)  { 'Hello.' }
      let(:strategy) { :unknown }

      it 'raises an ArgumentError' do
        expect { result }.to raise_error(ArgumentError)
      end
    end

    context 'when a disallowed strategy is given' do
      let(:content)  { 'Hello.' }
      let(:strategy) { :base_text }

      it 'raises an ArgumentError' do
        expect { result }.to raise_error(ArgumentError)
      end
    end

    context 'with a complex content example (English)' do
      let(:fixture) { Rails.root.join('spec/fixtures/files/ai/vectordb/content/long-text-001.html').read }
      let(:content) { Text::ContentCleanup.new(content: fixture).cleanup }

      it 'chunks the complex content correctly' do
        expect(result.length).to eq(9)
      end
    end

    context 'with a complex content example (German)' do
      let(:fixture) { Rails.root.join('spec/fixtures/files/ai/vectordb/content/long-text-002.html').read }
      let(:content) { Text::ContentCleanup.new(content: fixture).cleanup }

      it 'chunks the complex content correctly' do
        expect(result.length).to eq(7)
      end
    end
  end
end

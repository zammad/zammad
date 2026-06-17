# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Text::ContentCleanup do
  subject(:result) { described_class.new(content:).cleanup }

  describe '#cleanup' do
    context 'when content contains HTML' do
      let(:content) { '<p>Hello <strong>world</strong></p>' }

      it 'converts HTML to plain text' do
        expect(result).to eq('Hello world')
      end
    end

    context 'when content has more than 2 consecutive horizontal whitespace characters' do
      let(:content) { "foo  bar\tbaz   qux" }

      it 'compresses them to at most 1' do
        expect(result).to eq('foo bar baz qux')
      end
    end

    context 'when content has more than 2 consecutive newlines' do
      let(:content) { 'foo<br><br><br>bar' }

      it 'compresses them to at most 2' do
        expect(result).to eq("foo\n\nbar")
      end
    end

    context 'when content contains special symbols' do
      let(:content) { 'Hello ¶ world § test 🎉 done 🔥' }

      it 'removes pilcrows, section signs, and emojis' do
        expect(result).to eq('Hello world test done')
      end
    end

    context 'when content has leading and trailing whitespace' do
      let(:content) { "   hello world   \n" }

      it 'strips surrounding whitespace' do
        expect(result).to eq('hello world')
      end
    end

    context 'when content is already plain clean text' do
      let(:content) { 'Hello world' }

      it 'returns it unchanged' do
        expect(result).to eq('Hello world')
      end
    end

    context 'when content has repeated delimiter characters' do
      let(:content) { 'foo---bar ## baz__qux' }

      it 'normalizes delimiters without concatenating words' do
        expect(result).to eq('foo bar baz qux')
      end
    end

    context 'with a complex content example (English)' do
      let(:content) { Rails.root.join('spec/fixtures/files/ai/vectordb/content/long-text-001.html').read }

      it 'cleans up the complex content correctly' do
        expect(result.length).to eq(11_064)
      end
    end

    context 'with a complex content example (German)' do
      let(:content) { Rails.root.join('spec/fixtures/files/ai/vectordb/content/long-text-002.html').read }

      it 'cleans up the complex content correctly' do
        expect(result.length).to eq(10_946)
      end
    end
  end
end

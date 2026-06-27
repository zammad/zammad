# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Content::Chunks::Strategy::Recursive, :aggregate_failures do
  # Drive the strategy through the public dispatcher, the way the indexer calls it.
  def chunk(text, headers: [], **opts)
    Service::AI::VectorDB::Content::Chunks.execute(content: text, content_meta_headers: headers, strategy: :recursive, options: opts)
  end

  # estimate_tokens is the token oracle the chunker sizes against; assert the bound with it.
  def within_limit?(chunks, max_tokens)
    chunks.all? { |c| Service::AI::VectorDB::Content::Chunks::Strategy::Base.estimate_tokens(c) <= max_tokens }
  end

  it 'returns no chunks for blank content' do
    expect(chunk('   ')).to eq([])
  end

  it 'keeps short content as a single chunk' do
    expect(chunk('A short knowledge base answer.')).to eq(['A short knowledge base answer.'])
  end

  it 'splits on paragraph boundaries' do
    chunks = chunk("First para.\n\nSecond para.", max_tokens_per_chunk: 8, target_tokens: 4, overlap_tokens: 0)

    expect(chunks).to eq(['First para.', 'Second para.'])
  end

  context 'with English content longer than the target size' do
    let(:sentences) { Array.new(40) { |i| "This is sentence number #{i} with a handful of words." } }
    let(:text)      { sentences.join(' ') }
    let(:chunks)    { chunk(text, max_tokens_per_chunk: 40, target_tokens: 30, overlap_tokens: 6) }

    it 'splits into multiple chunks' do
      expect(chunks.length).to be > 1
    end

    it 'keeps every chunk within the model token limit' do
      expect(within_limit?(chunks, 40)).to be(true)
    end

    it 'overlaps consecutive chunks for context continuity' do
      first_tail   = chunks.first.split.last(3)
      second_start = chunks.second.split.first(12)

      expect(second_start).to include(*first_tail)
      expect(Service::AI::VectorDB::Content::Chunks::Strategy::Base.estimate_tokens(first_tail.join(' '))).to be <= 6
    end

    it 'preserves the content across the chunks' do
      expect(chunks.first).to start_with('This is sentence number 0')
      expect(chunks.last).to end_with('words.')
    end
  end

  it 'hard-splits a single sentence that exceeds the target size' do
    sentence = "#{(1..80).map { |i| "word#{i}" }.join(' ')}."
    chunks   = chunk(sentence, max_tokens_per_chunk: 24, target_tokens: 20, overlap_tokens: 0)

    expect(chunks.length).to be >= 3
    expect(within_limit?(chunks, 24)).to be(true)
  end

  # Regression: a no-space script counted as one whitespace "word" used to yield a single
  # oversized chunk (Strategy::Sentence still raises on it). It must split and stay within the limit.
  context 'with a no-space script (CJK)' do
    let(:text) { '中文段落。' * 300 } # ~1500 estimated tokens

    it 'splits a long document into multiple chunks instead of one' do
      expect(chunk(text).length).to be > 1
    end

    it 'keeps every chunk within the model token limit' do
      expect(within_limit?(chunk(text), described_class::DEFAULT_MAX_TOKENS)).to be(true)
    end
  end

  context 'when the embedding model has a small input limit' do
    it 'sizes chunks against that limit for every script' do
      samples = {
        english:      'The quick brown fox jumps over the lazy dog. ' * 40,
        german:       'Donaudampfschifffahrtsgesellschaftskapitänsmütze ist ein langes Wort. ' * 30,
        chinese:      '这是一个没有空格的中文段落，用来测试分块器。' * 40,
        japanese:     'これはスペースのない日本語の段落です。' * 40,
        thai:         'นี่คือย่อหน้าภาษาไทยที่ไม่มีช่องว่างระหว่างคำ' * 40,
        greek:        'Επανεκκινήστε την υπηρεσία και ελέγξτε τη σύνδεση. ' * 30,
        cyrillic:     'Перезапустите службу и проверьте соединение с базой данных. ' * 30,
        arabic:       'يرجى إعادة تشغيل الخدمة والتحقق من الاتصال بقاعدة البيانات. ' * 30,
        code:         "def call(text)\n  text.split(/\\s+/).map { |w| w.downcase }.join('-')\nend\n" * 20,
        long_url:     "https://example.com/#{'a' * 2000}",
        digits:       "Transaction reference: #{'1234567890' * 200} please advise.",
        symbols:      '=' * 2000,
        mixed_script: 'Error code 中文 0x1F: see https://example.com/docs/中文/page. ' * 30,
      }

      samples.each do |name, sample|
        chunks = chunk(sample, max_tokens_per_chunk: 64)

        expect(chunks.length).to be >= 1, "#{name}: expected at least one chunk"
        expect(within_limit?(chunks, 64)).to be(true), "#{name}: a chunk exceeded the token limit"
      end
    end
  end

  context 'with content_meta_headers' do
    let(:text)    { Array.new(20) { |i| "Sentence number #{i} of the body." }.join(' ') }
    let(:headers) { ['How to reset your password'] }
    let(:chunks)  { chunk(text, headers:, max_tokens_per_chunk: 40, target_tokens: 24, overlap_tokens: 0) }

    it 'prepends the meta headers to every chunk' do
      expect(chunks).to all(start_with("How to reset your password\n\n"))
    end

    it 'keeps chunk body plus headers within the model token limit' do
      expect(within_limit?(chunks, 40)).to be(true)
    end
  end
end

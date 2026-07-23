# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HasExcerpt do
  let(:model_class) do
    Class.new { include HasExcerpt }
  end

  def excerpt_for(text, **)
    model_class.new.excerpt_text(text, **)
  end

  it 'returns an empty string for a blank text' do
    expect(excerpt_for('')).to eq('')
  end

  it 'returns an empty string for nil' do
    expect(excerpt_for(nil)).to eq('')
  end

  it 'collapses runs of spaces/tabs to a single space' do
    expect(excerpt_for("Hello   \tworld.")).to eq('Hello world.')
  end

  it 'keeps a short text untouched, without an ellipsis' do
    text = 'One sentence. Two sentences. Three sentences.'
    expect(excerpt_for(text)).to eq(text)
  end

  context 'with line breaks' do
    it 'preserves line breaks between sentences' do
      expect(excerpt_for("First line.\nSecond line.")).to eq("First line.\nSecond line.")
    end

    it 'treats a line break as a sentence boundary even without punctuation' do
      expect(excerpt_for("A heading\nThen a sentence.")).to eq("A heading\nThen a sentence.")
    end

    it 'trims spaces hugging a line break' do
      expect(excerpt_for("First.  \n  Second.")).to eq("First.\nSecond.")
    end

    it 'collapses long runs of blank lines to a single blank line' do
      expect(excerpt_for("One.\n\n\n\nTwo.")).to eq("One.\n\nTwo.")
    end
  end

  context 'when the text is longer than the word target' do
    let(:text) { (['The quick brown fox jumps over the lazy dog again.'] * 10).join(' ') }

    it 'breaks on a sentence boundary and appends an ellipsis' do
      expect(excerpt_for(text)).to end_with('dog again. …')
    end

    it 'keeps whole sentences up to the target (5 sentences of 10 words + ellipsis)' do
      expect(excerpt_for(text).split(%r{(?<=[.!?])\s+}).count).to eq(6)
    end

    it 'never returns fewer words than the target once enough sentences exist' do
      word_count = excerpt_for(text).delete('…').split.size

      expect(word_count).to be >= described_class::EXCERPT_WORD_TARGET
    end

    it 'honours a custom word target' do
      expect(excerpt_for(text, word_target: 10)).to eq('The quick brown fox jumps over the lazy dog again. …')
    end
  end

  context 'when a single sentence is longer than the word cap' do
    let(:text) { "#{Array.new(200, 'word').join(' ')}." }

    it 'truncates the sentence at the word cap' do
      expect(excerpt_for(text).delete('…').split.size).to eq(described_class::EXCERPT_WORD_CAP)
    end

    it 'appends an ellipsis after the truncated sentence' do
      expect(excerpt_for(text)).to end_with('word …')
    end

    it 'honours a custom word cap' do
      expect(excerpt_for(text, word_cap: 3)).to eq('word word word …')
    end

    it 'caps the over-long sentence that crosses the target, counting earlier sentences' do
      # A short first sentence (5 words) followed by a 200-word sentence that crosses
      # the 50-word target: the excerpt is capped at 60 words total, not left unbounded.
      long = Array.new(200, 'word').join(' ')
      word_count = excerpt_for("One two three four five. #{long}.").delete('…').split.size

      expect(word_count).to eq(described_class::EXCERPT_WORD_CAP)
    end
  end

  context 'when a multi-line text exceeds the word target' do
    let(:line) { 'one two three four five six seven eight nine ten' }
    let(:text) { Array.new(10, line).join("\n") }

    it 'breaks on a line boundary and keeps the preserved line breaks' do
      expect(excerpt_for(text)).to eq("#{Array.new(5, line).join("\n")} …")
    end
  end

  context 'with paragraph-sized text' do
    # Builds a paragraph as sentences of ten words each, e.g.
    # paragraph('a', 'b') => "a a a a a a a a a a. b b b b b b b b b b."
    def paragraph(*words)
      words.map { |word| "#{([word] * 10).join(' ')}." }.join(' ')
    end

    it 'returns a single ~40-word paragraph in full, without an ellipsis' do
      text = paragraph('alpha', 'beta', 'gamma', 'delta') # 4 sentences * 10 words = 40

      expect(excerpt_for(text)).to eq(text)
    end

    it 'truncates several 40-word paragraphs at the word target on a paragraph boundary' do
      first  = paragraph('alpha', 'beta', 'gamma', 'delta')     # 40 words
      second = paragraph('epsilon', 'zeta', 'eta', 'theta')     # 40 words
      third  = paragraph('iota', 'kappa', 'lambda', 'mu')       # 40 words
      text   = [first, second, third].join("\n")

      # The 40 words of the first paragraph plus the first 10-word sentence of the
      # second paragraph reach the 50-word target, so it stops there.
      expected = "#{first}\n#{(['epsilon'] * 10).join(' ')}. …"

      expect(excerpt_for(text)).to eq(expected)
    end
  end

  describe '.has_excerpt' do
    it 'generates an attr_excerpt method reading the attribute as plain text' do
      klass = Class.new do
        include HasExcerpt

        has_excerpt :note

        attr_accessor :note
      end

      instance = klass.new.tap { |record| record.note = 'Hello world.' }

      expect(instance.note_excerpt).to eq('Hello world.')
    end

    it 'returns nil when the attribute is nil' do
      klass = Class.new do
        include HasExcerpt

        has_excerpt :note

        attr_accessor :note
      end

      expect(klass.new.note_excerpt).to be_nil
    end

    it 'forwards options such as word_target to the excerpt logic' do
      klass = Class.new do
        include HasExcerpt

        has_excerpt :note

        attr_accessor :note
      end

      instance = klass.new.tap { |record| record.note = 'One. Two. Three. Four.' }

      expect(instance.note_excerpt(word_target: 1)).to eq('One. …')
    end

    it 'always strips HTML to plain text' do
      klass = Class.new do
        include HasExcerpt

        has_excerpt :body

        attr_accessor :body
      end

      instance = klass.new.tap { |record| record.body = '<p>First paragraph.</p><p>Second <b>paragraph</b>.</p>' }

      expect(instance.body_excerpt).to eq("First paragraph.\nSecond paragraph.")
    end

    it 'keeps link text and decodes entities via html2text' do
      klass = Class.new do
        include HasExcerpt

        has_excerpt :body

        attr_accessor :body
      end

      instance = klass.new.tap { |record| record.body = 'Visit <a href="https://zammad.com">our site</a> &amp; enjoy.' }

      expect(instance.body_excerpt).to eq('Visit our site & enjoy.')
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Result verification for the translation prompt against a real provider (replayed from committed
# VCR cassettes). Add a scenario by dropping a JSON file into spec/fixtures/files/ai/translate/ -
# no code changes needed. To record a cassette for a new or changed fixture, delete its cassette
# under test/data/vcr_cassettes/services/service/ai/feature/translate/result/ and rerun with a
# real ZAMMAD_AI_TOKEN. Every prompt change invalidates every cassette here.
#
# What this can and cannot answer: it checks what makes a translation usable - the target
# language, the structure, the technical elements, that nothing was dropped, and that the model
# translated the text instead of answering it. Whether a translation reads well is not checkable
# here and stays a human judgement in the prompt evaluation.
#
# All assertions of a scenario live in one example on purpose: the cassette name is derived from
# the example, so one scenario stays one provider call and one recording.
RSpec.describe 'AI translation result verification', :aggregate_failures, integration: true, required_envs: %w[ZAMMAD_AI_TOKEN], use_vcr: true do # rubocop:disable RSpec/DescribeClass
  shared_examples 'when a translation is verified' do |fixture_path, locale|
    context "with #{fixture_path.basename} into #{locale}" do
      let(:scenario)         { JSON.parse(fixture_path.read) }
      let(:locale_code)      { locale }
      let(:input)            { scenario['input'].to_s }
      let(:html)             { scenario.fetch('html', true) }
      let(:reference)        { scenario.dig('expected_translation', locale_code) }
      let(:min_length_ratio) { scenario.fetch('min_length_ratio', 0.5) }

      # Any object can hold a translation; a ticket article is the first caller's object.
      let(:object) { create(:ticket_article, body: input, content_type: html ? 'text/html' : 'text/plain') }

      let(:translation) do
        Service::AI::Feature::Translate.execute(
          locale:               locale_code,
          context_data:         { object:, body: input, html:, backend: 'ai' },
          persistence_strategy: :request_only,
        ).content.to_s
      end

      it 'translates the content and preserves everything around it' do
        expect_target_language
        expect_structure
        expect_technical_elements
        expect_numbers
        expect_no_markdown
        expect_no_truncation
        expect_reference_similarity if reference
      end
    end
  end

  fixture_files = if ENV['AI_TRANSLATE_RESULT_INPUT_FILE']
                    [Rails.root.join("spec/fixtures/files/ai/translate/#{ENV['AI_TRANSLATE_RESULT_INPUT_FILE']}")]
                  else
                    Rails.root.glob('spec/fixtures/files/ai/translate/*.json')
                  end

  context 'with Zammad AI provider' do
    before do
      setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])
    end

    fixture_files.each do |fixture_path|
      # Read here rather than in a `let`, because the target locales define the example groups.
      JSON.parse(fixture_path.read).fetch('target_locales').each do |locale|
        include_examples 'when a translation is verified', fixture_path, locale
      end
    end
  end

  # The answer must be in the target language - the one thing a translation cannot get wrong.
  def expect_target_language
    detected = detect_language(translation)

    expect(detected).to eq(expected_language), advisory("answered in #{detected.inspect} instead of #{expected_language.inspect}")
  end

  # HTML in, the same markup out; plain text in, no markup and no merged paragraphs out.
  def expect_structure
    if html
      expect(tag_tree(translation)).to eq(tag_tree(input)), advisory('the markup of the answer differs from the input')
      return
    end

    expect(html_markup?(translation)).to be(false), advisory('the answer contains HTML tags, but the input was plain text')
    expect(content_lines(translation)).to eq(content_lines(input)), advisory('the answer has a different number of text lines than the input')
  end

  # Commands, paths, identifiers and URLs are the strings a translation must leave alone; the
  # scenario names the ones it contains.
  def expect_technical_elements
    Array(scenario['preserve']).each do |element|
      expect(translation).to include(element), advisory("#{element.inspect} is missing from the answer")
    end
  end

  # A quantity that changes is content damage a property check can still see. Digit groups are
  # compared as a multiset, so neither a locale-formatted number ("1,000" -> "1.000") nor a
  # reordered date ("2026-09-09" -> "09.09.2026") counts as a failure.
  def expect_numbers
    answered = digit_groups(text_of(translation))

    digit_groups(text_of(input)).each do |group, count|
      expect(answered[group].to_i).to be >= count, advisory("#{group.inspect} appears #{answered[group].to_i} times in the answer instead of #{count}")
    end
  end

  # The prompt asks for HTML or plain text, never Markdown, and for no code fences around the
  # answer - both would be rendered verbatim to the reader.
  def expect_no_markdown
    expect(translation).not_to match(%r{```|\*\*|^\#{1,6}\s}), advisory('the answer contains Markdown')
  end

  # Gross omission guard: a model that answers a long text with a single sentence, or follows an
  # instruction inside the text instead of translating it, lands far below the input length. The
  # floor is per scenario, because a compact target script needs legitimately fewer characters.
  def expect_no_truncation
    ratio = text_of(translation).length.to_f / text_of(input).length

    expect(ratio).to be >= min_length_ratio, advisory("the answer is #{(ratio * 100).round}% of the input length")
  end

  # The one check that reaches the meaning: is the answer the same statement as a human
  # translation of the input. Both texts are embedded in a single request on purpose - VCR replays
  # repeated calls to the same URI with the first recorded response, so two separate calls would
  # compare a vector with itself. The threshold is calibrated against the recorded answers.
  def expect_reference_similarity
    vectors = AI::ProviderConnection.for_embeddings.provider_instance.bulk_embed(input: [text_of(translation), text_of(reference)])

    expect(vectors.size).to eq(2), advisory('the provider did not answer with one vector per input')

    similarity = cosine_similarity(*vectors)

    expect(similarity).to be >= 0.8, advisory("the answer is only #{(similarity * 100).round}% similar to the reference translation")
  end

  def expected_language
    locale_code.split('-').first
  end

  # Nested rather than a flat list of tag names, which cannot tell
  # <blockquote><p>Zitat</p></blockquote> apart from <blockquote></blockquote><p>Zitat</p>.
  def tag_tree(string)
    element_tree(Nokogiri::HTML5.fragment(string))
  end

  def element_tree(node)
    node.element_children.map { |child| [child.name, element_tree(child)] }
  end

  def content_lines(string)
    string.lines.count(&:present?)
  end

  def digit_groups(string)
    string.scan(%r{\d+}).tally
  end

  def text_of(string)
    html ? string.html2text : string.to_s
  end

  def html_markup?(text)
    return false if text&.strip.blank?

    # Simple heuristic: detect presence of an HTML-like opening tag
    text.match?(%r{<\s*[A-Za-z][A-Za-z0-9]*(?:\s|/|>)})
  end

  # Link text is translated but its URL is not, so the URL would skew the detection.
  def detect_language(text)
    text = text.to_s.gsub(%r{<a\b[^>]*>(.*?)</a>}im, '\\1')

    CLD.detect_language(text.html2text)[:code]
  end

  def cosine_similarity(one, other)
    dot = one.each_with_index.sum { |value, index| value * other[index] }

    dot / (Math.sqrt(one.sum { |value| value**2 }) * Math.sqrt(other.sum { |value| value**2 }))
  end

  def advisory(message)
    lambda do
      "#{message}\n\nInput:\n#{input}\n\nAnswer:\n#{translation}"
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Result verification for the knowledge base answer prompt against a real provider (replayed from
# committed VCR cassettes). Add a scenario by dropping a JSON file into
# spec/fixtures/files/ai/knowledge_base_answer_from_ticket/ - no code changes needed. To record a
# cassette for a new or changed fixture, delete its cassette under
# test/data/vcr_cassettes/services/service/ai/feature/knowledge_base_answer_from_ticket/result/ and
# rerun with a real ZAMMAD_AI_TOKEN. The replay matches requests by URI only, so a changed prompt
# still replays the old recordings: delete all cassettes and re-record after every prompt change.
#
# The answer is filed under the locale it is generated for, so it has to be written in that
# language, whatever language the ticket is in.
#
# All assertions of a scenario live in one example on purpose: the cassette name is derived from
# the example, so one scenario stays one provider call and one recording.
RSpec.describe 'AI knowledge base answer result verification', :aggregate_failures, integration: true, required_envs: %w[ZAMMAD_AI_TOKEN], use_vcr: true do # rubocop:disable RSpec/DescribeClass
  shared_examples 'when a knowledge base answer is verified' do |fixture_path, locale|
    context "with #{fixture_path.basename} into #{locale}" do
      let(:scenario)          { JSON.parse(fixture_path.read) }
      let(:locale_code)       { locale }
      let(:expected_language) { locale_code.split('-').first }

      let(:ticket) do
        ticket = create(:ticket, title: scenario['ticket']['title'])
        scenario['ticket']['articles'].each do |article|
          create(:ticket_article, ticket:, sender_name: article['sender'], internal: article.fetch('internal', false), body: article['body'])
        end
        ticket
      end

      let(:answer) do
        Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent
          .with_current_user(create(:agent))
          .execute(ticket:, locale: locale_code, category_options: [{ value: 1, label: 'General' }])
          .content
      end

      it 'writes the article in the target language and keeps its technical elements' do
        expect_target_language
        expect_headings_in_target_language
        expect_technical_elements
      end
    end
  end

  context 'with Zammad AI provider' do
    before do
      setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])
    end

    Rails.root.glob('spec/fixtures/files/ai/knowledge_base_answer_from_ticket/*.json').each do |fixture_path|
      # Read here rather than in a `let`, because the target locales define the example groups.
      JSON.parse(fixture_path.read).fetch('target_locales').each do |locale|
        include_examples 'when a knowledge base answer is verified', fixture_path, locale
      end
    end
  end

  def expect_target_language
    expect(detect_language(answer['title'])).to eq(expected_language), advisory("the title is not in #{expected_language.inspect}")
    expect(detect_language(answer['body'])).to eq(expected_language), advisory("the body is not in #{expected_language.inspect}")
  end

  # CLD cannot judge a one-word heading, so this checks for the one failure the prompt warns
  # about: English section names carried over from the prompt into an article in another language.
  def expect_headings_in_target_language
    return if expected_language == 'en'

    headings = Nokogiri::HTML5.fragment(answer['body']).css('h1, h2, h3, h4, h5, h6').map { |heading| heading.text.strip }

    headings.each do |heading|
      expect(%w[Cause Resolution Prevention]).not_to include(heading), advisory("the heading #{heading.inspect} is in English")
    end
  end

  # Values, identifiers and product names from the ticket have to survive the translation; the
  # scenario names the ones it contains.
  def expect_technical_elements
    Array(scenario['preserve']).each do |element|
      expect(answer['body']).to include(element), advisory("#{element.inspect} is missing from the body")
    end
  end

  def detect_language(text)
    CLD.detect_language(text.to_s.html2text)[:code]
  end

  def advisory(message)
    lambda do
      "#{message}\n\nTitle:\n#{answer['title']}\n\nBody:\n#{answer['body']}"
    end
  end
end

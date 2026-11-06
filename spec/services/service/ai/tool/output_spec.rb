# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Output do
  describe '.time' do
    before do
      travel_to Time.zone.parse('2026-10-05 08:12:00 UTC')
      Setting.set('timezone_default', 'Europe/Berlin')
    end

    it 'shows a time to the minute in the system time zone' do
      expect(described_class.time(Time.current)).to eq('2026-10-05 10:12')
    end
  end

  describe '.time_zone' do
    it 'is the system time zone' do
      Setting.set('timezone_default', 'Europe/Berlin')

      expect(described_class.time_zone).to eq('Europe/Berlin')
    end
  end

  describe '.shared_lengths' do
    it 'gives each text an even share, and passes what a shorter one leaves on to the longer ones' do
      expect(described_class.shared_lengths([100, 5_000, 5_000], budget: 3_000)).to eq([1_000, 1_450, 1_450])
    end

    it 'keeps the order the texts were given in' do
      expect(described_class.shared_lengths([5_000, 100], budget: 3_000)).to eq([2_900, 1_500])
    end

    it 'gives a single text all of it' do
      expect(described_class.shared_lengths([50_000], budget: 40_000)).to eq([40_000])
    end

    it 'returns nothing for no texts' do
      expect(described_class.shared_lengths([], budget: 3_000)).to eq([])
    end
  end

  # The marking recognises copies of these forms by patterns of its own, which have to follow a changed form.
  describe 'its forms copied into a text', :aggregate_failures do
    let(:ticket)      { create(:ticket, title: 'Calendar does not sync') }
    let(:article)     { create(:ticket_article, ticket:, subject: 'Calendar does not sync', body: 'Since the update.', content_type: 'text/plain') }
    let(:translation) { create(:knowledge_base_answer, :internal, translation_attributes: { title: 'Outlook sync' }).translations.first }

    # Every line of a part outside its marked texts: the facts of a row and the tags.
    def form_lines(*parts)
      parts.flat_map { |part| part.text.lines.map(&:chomp) }.reject { |line| line.start_with?(AI::PromptText::LINE_MARK) }
    end

    it 'labels a copy of every row and every tag the tools write' do
      lines = form_lines(
        described_class::Ticket.row(ticket, facts: ['the parent of this ticket']),
        described_class::KnowledgeBaseAnswer.part(translation, length: 100, edited_at: Time.current),
        described_class::Message.part(article, position: 4, text: 'Since the update.', length: 100),
      )

      expect(lines.size).to eq(10)
      lines.each do |line|
        expect(AI::PromptText.marked_text(line, source: 'customer').lines.second).to start_with("│ #{AI::PromptText::IMITATED_HEADER_LABEL}"), line
      end
    end
  end
end

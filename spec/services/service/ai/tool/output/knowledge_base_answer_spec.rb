# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Output::KnowledgeBaseAnswer, :aggregate_failures do
  before do
    travel_to Time.zone.parse('2026-10-05 08:12:00 UTC')
    Setting.set('timezone_default', 'Europe/Berlin')
  end

  describe '.row' do
    let(:translation) { create(:knowledge_base_answer, :published, translation_attributes: { title: 'Outlook sync after an update' }).translations.first }

    it 'names the answer by its ID and the locale of its text, its title marked as the knowledge base\'s' do
      row = described_class.row(translation)

      expect(row.content).to eq(type: 'KnowledgeBase::Answer', id: translation.answer_id, title: 'Outlook sync after an update', locale: translation.kb_locale.system_locale.locale)
      expect(row.text).to eq(<<~TEXT.chomp)
        Knowledge base answer #{translation.answer_id} · #{translation.kb_locale.system_locale.locale}
        <text source="knowledge_base" field="title">
        │ Outlook sync after an update
        </text>
      TEXT
    end
  end

  describe '.part' do
    let(:answer)      { create(:knowledge_base_answer, :internal, translation_attributes: { title: 'Outlook sync after an update' }) }
    let(:translation) { answer.translations.first.tap { |translation| translation.content.update!(body: '<p>Remove the account.</p><p>Add it again.</p>') } }
    let(:locale)      { translation.kb_locale.system_locale.locale }

    it 'gives the answer as a row with its whole text where it fits, marked as the knowledge base\'s' do
      part = described_class.part(translation, length: 100, edited_at: Time.current)

      expect(part.content).to eq(
        type: 'KnowledgeBase::Answer', id: answer.id, title: 'Outlook sync after an update', locale:,
        visibility: 'internal', edited_at: Time.current, text: "Remove the account.\nAdd it again.", truncated: false,
      )
      expect(part.text).to eq(<<~TEXT.chomp)
        Knowledge base answer #{answer.id} · #{locale} · internal · updated 2026-10-05 10:12
        <text source="knowledge_base" field="title">
        │ Outlook sync after an update
        </text>
        <text source="knowledge_base" answer="#{answer.id}">
        │ Remove the account.
        │ Add it again.
        </text>
      TEXT
    end

    it 'shows the passage that matched a search where the text does not fit, and says how much is shown' do
      part = described_class.part(translation, length: 15, passage: 'Add it again.')

      expect(part.content).to include(visibility: 'internal', text: 'Add it again.', truncated: true, part: 'passage', full_length: 33)
      expect(part.text).to include(%(<text source="knowledge_base" answer="#{answer.id}" cut="the passage that matched, 13 of 33 characters shown">))
    end

    it 'shows the start without a passage, and leaves out what it was not given' do
      part = described_class.part(translation, length: 15, content: { contains: 'E1001' }, facts: ['contains E1001'])

      expect(part.content).to include(text: 'Remove the …', part: 'start', contains: 'E1001').and not_include(:edited_at)
      expect(part.text).to start_with("Knowledge base answer #{answer.id} · #{locale} · internal · contains E1001\n")
      expect(part.text).to include(%(cut="12 of 33 characters shown"))
    end

    it 'names a published answer public' do
      published = create(:knowledge_base_answer, :published).translations.first

      expect(described_class.part(published, length: 100).content).to include(visibility: 'public')
    end
  end
end

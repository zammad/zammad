# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Output::KnowledgeBaseAnswer, :aggregate_failures do
  before do
    travel_to Time.zone.parse('2026-10-05 08:12:00 UTC')
    Setting.set('timezone_default', 'Europe/Berlin')
  end

  let(:knowledge_base) { create(:knowledge_base) }
  let(:top_category)   { create(:knowledge_base_category, knowledge_base:).tap { |category| category.translations.first.update!(title: 'Email') } }
  let(:category)       { create(:knowledge_base_category, parent: top_category).tap { |category| category.translations.first.update!(title: 'Outlook') } }

  describe '.row' do
    let(:translation) { create(:knowledge_base_answer, :published, category:, translation_attributes: { title: 'Outlook sync after an update' }).translations.first }

    it 'names the answer by its ID, the locale of its text and its category, its title marked as the knowledge base\'s' do
      row = described_class.row(translation)

      expect(row.content).to eq(
        type: 'KnowledgeBase::Answer', id: translation.answer_id, title: 'Outlook sync after an update', locale: translation.kb_locale.system_locale.locale,
        category: { id: category.id, path: 'Email / Outlook' },
      )
      expect(row.text).to eq(<<~TEXT.chomp)
        Knowledge base answer #{translation.answer_id} · #{translation.kb_locale.system_locale.locale} · category Email / Outlook
        <text source="knowledge_base" field="title">
        │ Outlook sync after an update
        </text>
      TEXT
    end
  end

  describe '.part' do
    let(:answer)      { create(:knowledge_base_answer, :internal, category:, translation_attributes: { title: 'Outlook sync after an update' }) }
    let(:translation) { answer.translations.first.tap { |translation| translation.content.update!(body: '<p>Remove the account.</p><p>Add it again.</p>') } }
    let(:locale)      { translation.kb_locale.system_locale.locale }

    it 'gives the answer as a row with its whole text where it fits, marked as the knowledge base\'s' do
      part = described_class.part(translation, length: 100, edited_at: Time.current)

      expect(part.content).to eq(
        type: 'KnowledgeBase::Answer', id: answer.id, title: 'Outlook sync after an update', locale:, category: { id: category.id, path: 'Email / Outlook' },
        visibility: 'internal', edited_at: Time.current, text: "Remove the account.\nAdd it again.", truncated: false,
      )
      expect(part.text).to eq(<<~TEXT.chomp)
        Knowledge base answer #{answer.id} · #{locale} · category Email / Outlook · internal · updated 2026-10-05 10:12
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
      expect(part.text).to start_with("Knowledge base answer #{answer.id} · #{locale} · category Email / Outlook · internal · contains E1001\n")
      expect(part.text).to include(%(cut="12 of 33 characters shown"))
    end

    it 'names a published answer public' do
      published = create(:knowledge_base_answer, :published).translations.first

      expect(described_class.part(published, length: 100).content).to include(visibility: 'public')
    end

    it 'names the tags where it is given them' do
      part = described_class.part(translation, length: 100, tags: %w[outlook sync])

      expect(part.content).to include(tags: %w[outlook sync])
      expect(part.text).to start_with("Knowledge base answer #{answer.id} · #{locale} · category Email / Outlook · internal · tags: outlook, sync\n")
      expect(described_class.part(translation, length: 100, tags: []).content).to include(tags: [])
    end
  end

  describe '.categories' do
    let(:kb_locale)   { create(:knowledge_base_locale, knowledge_base:, system_locale: Locale.find_by(locale: 'de-de')) }
    let(:answer)      { create(:knowledge_base_answer, :published, category:) }
    let(:english)     { answer.translations.first }
    let(:german)      { create(:knowledge_base_answer_translation, answer:, kb_locale:) }
    let(:other)       { create(:knowledge_base_answer, :published, category: top_category).translations.first }

    before { create(:knowledge_base_category_translation, category: top_category, kb_locale:, title: 'E-Mail') }

    it 'gives each text the path of its category, titled in the text\'s locale where the category has it, from two queries' do
      translations = [english, german, other]
      ActiveRecord::Associations::Preloader.new(records: translations, associations: :answer).call
      categories = nil
      queries    = 0
      callback   = ->(*, payload) { queries += 1 if !payload[:cached] && payload[:name] != 'SCHEMA' }

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { categories = described_class.categories(translations) }

      expect(queries).to eq(2)
      expect(categories).to eq(
        english.id => { id: category.id, path: 'Email / Outlook' },
        german.id  => { id: category.id, path: 'E-Mail / Outlook' },
        other.id   => { id: top_category.id, path: 'Email' },
      )
    end
  end

  describe '.tags' do
    let(:answer) { create(:knowledge_base_answer, :published, category:) }
    let(:other)  { create(:knowledge_base_answer, :published, category:) }

    it 'gives each answer its tags, an empty list for one without' do
      answer.tag_add('sync', 1)
      answer.tag_add('outlook', 1)

      expect(described_class.tags([answer.id, other.id])).to eq(answer.id => answer.tag_list, other.id => [])
      expect(answer.tag_list).to contain_exactly('sync', 'outlook')
    end
  end
end

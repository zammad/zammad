# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'inserting Knowledge Base answer', searchindex: true, type: :system do
  include_context 'basic Knowledge Base'

  let(:field)              { find(:richtext) }
  let(:target_translation) { answer.translations.first }

  before do
    answer
    searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
  end

  context 'when published answer' do
    let(:answer) { published_answer }

    it 'adds text' do
      open_page
      insert_kb_answer(target_translation, field)

      expect(field).to have_text target_translation.content.body
    end

    it 'attaches file' do
      open_page
      insert_kb_answer(target_translation, field)

      within(:active_content) do
        within '.attachments .attachment--row' do
          store_object = Store.where(store_object_id: Store::Object.lookup(name: 'UploadCache')).last
          expect(page).to have_css ".attachment-delete[data-id='#{store_object.id}']", visible: :all # delete button is hidden by default
        end
      end
    end
  end

  context 'when answer title contains an ampersand' do
    let(:answer) { create(:knowledge_base_answer, :published, category:, translation_attributes: { title: 'Warranty & Returns' }) }

    it 'lists the title as text' do
      open_page
      search_kb_answer(target_translation, field)

      expect(find(:text_module, target_translation.id)).to have_text('Warranty & Returns')
    end
  end

  context 'when answer with image' do
    let(:answer) { create(:knowledge_base_answer, :with_image, published_at: 1.week.ago) }

    it 'inserts image' do
      open_page
      insert_kb_answer(target_translation, field)

      within(:active_content) do
        within(:richtext) do
          wait.until do
            elem   = first('img')
            height = elem.evaluate_script('this.naturalWidth') # driver-agnostic, unlike driver.browser.execute_script

            next false if height <= 0

            expect(height).to be_positive
          end
        end
      end
    end
  end

  context 'when answer with video' do
    let(:answer) { create(:knowledge_base_answer, :with_video, published_at: 1.week.ago) }

    it 'inserts a link to the video instead of the video marker' do
      open_page
      insert_kb_answer(target_translation, field)

      expect(field).to have_link('https://www.youtube.com/watch?v=vTTzwJsHpU8', href: 'https://www.youtube.com/watch?v=vTTzwJsHpU8')
      expect(field).to have_no_text('widget: video')
    end
  end

  context 'when creating a ticket' do
    let(:answer) { published_answer }

    it 'shows only the hint before a search term is typed' do
      open_page
      field.send_keys('??')

      expect(page).to have_css('.shortcut > ul > li', count: 1, text: 'Start typing to search in Knowledge Base…')
    end
  end

  context 'when replying to a ticket with a linked and a suggested answer', authenticated_as: :authenticate do
    let(:answer)                { published_answer }
    let(:ticket)                { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:suggested_translation) { internal_answer.translations.first }
    let(:suggestions_enabled)   { true }
    let(:found_suggestions)     { { answers: [{ translation: suggested_translation, score: 0.9 }], pending: false } }
    let(:suggestions)           { found_suggestions }
    let(:category_title)        { category.translations.first.title }
    let(:several_locales)       { false }

    def authenticate
      setup_ai_provider('zammad_ai')
      Setting.set('vectordb_enabled', true)
      Setting.set('ai_assistance_kb_answer_suggestions', suggestions_enabled)

      allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
      # The knowledge base answer factory triggers the vector index callback, which must not reach
      #   Elasticsearch in this spec.
      allow(Service::AI::VectorDB::Available).to receive(:execute).with(ping: false).and_return(false)
      allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers)
        .to receive(:execute).and_return(suggestions)

      create(:link, from: ticket, to: target_translation)
      alternative_locale if several_locales

      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"

      # The `??` list reads the sidebar's answers, so wait until they are there.
      within :active_content do
        find('.link_kb_answers', text: target_translation.title)
        find('.link_kb_answers', text: suggested_translation.title) if suggestions_enabled && !suggestions[:pending]
      end
    end

    it 'lists the linked answer, then the suggested one, below the hint, each with its category' do
      field.send_keys('??')

      expect(page).to have_selector(:text_module, target_translation.id)
      expect(all('.shortcut > ul > li').map(&:text)).to eq [
        'Start typing to search in Knowledge Base…',
        'Related knowledge',
        "#{category_title}\n#{target_translation.title}",
        'Suggested knowledge',
        "#{category_title}\n#{suggested_translation.title}",
      ]
    end

    it 'inserts a listed answer with its attachment' do
      field.send_keys('??')
      find(:text_module, target_translation.id).click

      expect(field).to have_text(target_translation.content.body)

      within(:active_content) do
        expect(page).to have_css('.attachments .attachment--row', text: 'hello_world.txt')
      end
    end

    it 'skips the section headers with the arrow keys' do
      field.send_keys('??')
      expect(page).to have_css('.shortcut li.is-active', text: target_translation.title)

      field.send_keys(:down)
      expect(page).to have_css('.shortcut li.is-active', text: suggested_translation.title)

      field.send_keys(:enter)
      expect(field).to have_text(suggested_translation.content.body)
    end

    it 'replaces the list with the search results when typing' do
      field.send_keys('??')
      expect(page).to have_css('.shortcut li.dropdown-header', text: 'Related knowledge')

      target_translation.title.slice(0, 3).chars.each { |letter| field.send_keys(letter) }

      expect(page).to have_css(".shortcut > ul > li.with-category[data-id='#{target_translation.id}']")
      expect(page).to have_no_css('.shortcut li.dropdown-header', text: 'Related knowledge')
    end

    context 'when the knowledge base has several locales' do
      let(:several_locales) { true }

      it 'shows the locale next to the title, as the search results do' do
        field.send_keys('??')

        locale = target_translation.kb_locale.system_locale.locale.upcase

        expect(page).to have_selector(:text_module, target_translation.id, text: "#{target_translation.title} (#{locale})")
      end
    end

    context 'when suggestions are switched off' do
      let(:suggestions_enabled) { false }

      it 'lists the linked answer only' do
        field.send_keys('??')

        expect(page).to have_selector(:text_module, target_translation.id)
        expect(page).to have_no_css('.shortcut li', text: 'Suggested knowledge')
        expect(page).to have_no_selector(:text_module, suggested_translation.id)
      end
    end

    context 'when the suggestions are still being searched' do
      let(:suggestions) { { answers: [], pending: true } }

      it 'lists the linked answer only, and adds the suggestions to the open list once they are found' do
        field.send_keys('??')

        expect(page).to have_selector(:text_module, target_translation.id)
        expect(page).to have_no_css('.shortcut li', text: 'Suggested knowledge')

        allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).to receive(:execute).and_return(found_suggestions)
        page.execute_script("App.Event.trigger('ticket::related_knowledge_base_answers::ping', { ticket_id: #{ticket.id} })")

        expect(page).to have_selector(:text_module, suggested_translation.id)
        expect(page).to have_css('.shortcut li.is-active', text: target_translation.title)
      end
    end

    it 'drops the suggestions from the open list when they fail' do
      field.send_keys('??')
      expect(page).to have_selector(:text_module, suggested_translation.id)

      page.execute_script("App.Event.trigger('ticket::related_knowledge_base_answers::ping', { ticket_id: #{ticket.id}, error: true })")

      expect(page).to have_no_selector(:text_module, suggested_translation.id)
      expect(page).to have_selector(:text_module, target_translation.id)
    end
  end

  private

  def open_page
    visit 'ticket/create'
  end

  def insert_kb_answer(translation, target_field)
    search_kb_answer(translation, target_field)

    find(:text_module, translation.id).click
  end

  def search_kb_answer(translation, target_field)
    target_field.send_keys('??')
    translation.title.slice(0, 3).chars.each { |letter| target_field.send_keys(letter) }
  end
end

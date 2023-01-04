# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  context 'when answer with image' do
    let(:answer) { create(:knowledge_base_answer, :with_image, published_at: 1.week.ago) }

    it 'inserts image' do
      open_page
      insert_kb_answer(target_translation, field)

      within(:active_content) do
        within(:richtext) do
          wait.until do
            elem   = first('img')
            script = 'return arguments[0].naturalWidth;'
            height = Capybara.current_session.driver.browser.execute_script(script, elem.native)

            expect(height).to be_positive
          end
        end
      end
    end
  end

  private

  def open_page
    visit 'ticket/create'
  end

  def insert_kb_answer(translation, target_field)
    target_field.send_keys('??')
    translation.title.slice(0, 3).chars.each { |letter| target_field.send_keys(letter) }

    find(:text_module, translation.id).click
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'inserting Knowledge Base answer', type: :system, authenticated_as: true, searchindex: true do
  include_context 'basic Knowledge Base'

  let(:field) { find(:richtext) }
  let(:target_translation) { answer.translations.first }

  before do
    configure_elasticsearch(required: true, rebuild: true) do
      answer
    end
  end

  context 'given published answer' do
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
        expect(page).to have_css '.attachments .attachment--row'
      end
    end
  end

  context 'given answer with image' do
    let(:answer) { create(:knowledge_base_answer, :with_image, published_at: 1.week.ago) }

    it 'inserts image' do
      open_page
      insert_kb_answer(target_translation, field)

      within(:active_content) do
        within(:richtext) do
          wait(5).until do
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

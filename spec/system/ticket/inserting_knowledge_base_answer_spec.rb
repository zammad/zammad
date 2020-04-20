require 'rails_helper'

RSpec.describe 'inserting Knowledge Base answer', type: :system, authenticated: true, searchindex: true do
  include_context 'basic Knowledge Base'

  let(:field) { find(:richtext) }
  let(:target_translation) { published_answer.translations.first }

  before do
    configure_elasticsearch(required: true, rebuild: true) do
      published_answer
    end
  end

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

  private

  def open_page
    visit 'ticket/create'
  end

  def insert_kb_answer(translation, target_field)
    target_field.send_keys('??')
    translation.title.slice(0, 3).split('').each { |letter| target_field.send_keys(letter) }

    find(:text_module, translation.id).click
  end
end

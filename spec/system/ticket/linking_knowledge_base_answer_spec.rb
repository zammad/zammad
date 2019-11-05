require 'rails_helper'

RSpec.describe 'linking Knowledge Base answer', type: :system, authenticated: true, searchindex: true do
  include_context 'basic Knowledge Base'

  before do
    configure_elasticsearch(required: true, rebuild: true) do
      published_answer
    end

    # refresh page to make sure it reflects updated settings
    refresh
  end

  it do
    ticket = create :ticket, group: Group.find_by(name: 'Users')
    visit "#ticket/zoom/#{ticket.id}"

    find(:css, '.active .link_kb_answers .js-add').click

    target_translation = published_answer.translations.first

    find(:css, '.active .link_kb_answers .js-input').send_keys target_translation.title

    find(:css, %(.active .link_kb_answers li[data-value="#{target_translation.id}"])).click

    expect(find(:css, '.active .link_kb_answers ol')).to have_text target_translation.title
  end
end

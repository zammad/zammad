# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Zoom > Telegram reply', authenticated_as: :user, type: :system do
  let(:article) { create(:telegram_article) }
  let(:ticket)  { article.ticket }
  let(:user)    { create(:agent, groups: [ticket.group]) }

  before do
    visit "#ticket/zoom/#{ticket.id}"
  end

  it 'keeps the line breaks of a multi-line reply' do
    within(:active_content) do
      click_on 'reply'
      find(:richtext).send_keys('Hello', :enter, '1', :enter, :enter, '2')
      click '.js-submit'

      # Playwright reports three line breaks around the empty line (<div><br></div>), Selenium two.
      expect(page).to have_css('.textBubble', text: %r{Hello\n1\n{2,3}2})
    end

    expect(Ticket::Article.last).to have_attributes(
      type:         have_attributes(name: 'telegram personal-message'),
      content_type: 'text/plain',
      body:         "Hello\n1\n\n2\n",
    )
  end
end

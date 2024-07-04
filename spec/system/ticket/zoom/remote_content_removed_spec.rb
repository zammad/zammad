# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Zoom > Remote Content Removed', authenticated_as: :user, type: :system do
  let(:article)     { create(:ticket_article, :inbound_email, ticket: ticket, preferences: preferences) }
  let(:preferences) { { remote_content_removed: true } }
  let(:ticket)      { create(:ticket) }
  let(:user)        { create(:agent, groups: [ticket.group]) }

  before do
    article

    visit "#ticket/zoom/#{ticket.id}"
  end

  context 'when a mail with an inline image is received' do
    it 'shows a message that the image was removed' do
      within(:active_content) do
        expect(page).to have_text('This message contains images or other content hosted by an external source. It was blocked, but you can download the original formatting here.')
      end
    end

    it 'shows a button to retrieve the original formatting' do
      within(:active_content) do
        expect(page).to have_css('.js-fetchOriginalFormatting')
      end
    end
  end
end

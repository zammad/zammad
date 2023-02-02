# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Articles', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:cid)    { "#{SecureRandom.uuid}@zammad.example.com" }
  let(:ticket) { create(:ticket, title: 'Ticket Title', group: group) }
  let(:article) do
    create(:ticket_article, :outbound_email, ticket: ticket, to: 'Zammad CI <ci@zammad.org>', content_type: 'text/html', body: "<img src=\"cid:#{cid}\"> some text").tap do |article|
      create(
        :store,
        object:      'Ticket::Article',
        o_id:        article.id,
        data:        'fake',
        filename:    'inline_image.jpg',
        preferences: {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => "<#{cid}>",
          'Content-Disposition' => 'inline',
        }
      )
      create(
        :store,
        object:      'Ticket::Article',
        o_id:        article.id,
        data:        'fake',
        filename:    'attached_image.jpg',
        preferences: {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => "<#{cid}.not.referenced>",
          'Content-Disposition' => 'inline',
        }
      )
    end
  end

  context 'when looking at a ticket' do
    it 'shows inline images and attachments correctly' do
      visit "/tickets/#{article.ticket_id}"

      wait_for_gql 'apps/mobile/pages/ticket/graphql/queries/ticket.graphql'
      expect(page).to have_text('Ticket Title')

      # Inline image is present with cid: replaced by REST API URL.
      expect(page).to have_css('img[src^="/api/v1/ticket_attachment"]')
      # Inline image does not show in attachments list.
      expect(page).to have_no_text('inline_image')
      # Attached image does show in attachments list.
      expect(page).to have_text('attached_image')
    end
  end
end

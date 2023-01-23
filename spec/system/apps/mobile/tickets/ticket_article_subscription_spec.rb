# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Articles > Update', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:ticket)   { create(:ticket, title: 'Ticket Title', group: group) }

  context 'when subscription is triggered' do
    let!(:article) { create(:ticket_article, body: 'Hello, World!', ticket: ticket, internal: false) }

    it 'updates article on the frontend' do
      visit "/tickets/#{ticket.id}"

      expect(page).to have_text(article.body)
      expect(page).to have_no_css("#article-#{article.id}.Internal")

      article.update!(internal: true)

      wait_for_gql('apps/mobile/pages/ticket/graphql/subscriptions/ticketArticlesUpdates.graphql')

      expect(page).to have_css("#article-#{article.id}.Internal")
    end

    it 'removes article on the frontend' do
      visit "/tickets/#{ticket.id}"

      expect(page).to have_css("#article-#{article.id}")

      article.destroy!

      wait_for_gql('apps/mobile/pages/ticket/graphql/subscriptions/ticketArticlesUpdates.graphql')

      expect(page).to have_no_css("#article-#{article.id}")
    end

    it 'adds new article on the frontend' do
      visit "/tickets/#{ticket.id}"

      expect(page).to have_css("#article-#{article.id}")

      new_article = create(:ticket_article, ticket: ticket, internal: false)

      wait_for_gql('apps/mobile/pages/ticket/graphql/subscriptions/ticketArticlesUpdates.graphql')

      expect(page).to have_css("#article-#{article.id}")
      expect(page).to have_css("#article-#{new_article.id}")
    end

  end

end

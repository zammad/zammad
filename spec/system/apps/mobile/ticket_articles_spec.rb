# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Articles', type: :system, app: :mobile, authenticated_as: :agent do
  let(:group)                { create(:group) }
  let(:agent)                { create(:agent, groups: [group]) }

  context 'when opening ticket with a single article' do
    let(:ticket) { create(:ticket, title: 'Ticket Title', group: group) }
    let!(:article) { create(:ticket_article, body: 'Article 1', ticket: ticket, internal: false) }

    it 'see a single article and no "load more"' do
      visit "/tickets/#{ticket.id}"
      expect(page).to have_text(article.body)
      expect(page).to have_no_text('load')
    end
  end

  context 'when opening ticket with 6 articles page' do
    let(:ticket) { create(:ticket, title: 'Ticket Title', group: group) }
    let!(:articles) do
      (1..6).map do |number|
        create(:ticket_article, body: "Article #{number}", ticket: ticket)
      end
    end

    it 'see all 6 articles' do
      visit "/tickets/#{ticket.id}"

      articles.each do |article|
        expect(page).to have_text(article.body, count: 1)
      end

      expect(page).to have_no_text('load')
    end
  end

  context 'when opening ticket with a lot of articles' do
    let(:ticket) { create(:ticket, title: 'Ticket Title', group: group) }
    let!(:articles) do
      (1..10).map do |number|
        create(:ticket_article, body: "Article #{number}.", ticket: ticket)
      end
    end

    it 'can use "load more" button' do
      visit "/tickets/#{ticket.id}"

      expect(page).to have_text('Article 1.')

      (5..9).each do |number|
        expect(page).to have_text(articles[number].body, count: 1)
      end

      expect(page).to have_no_text('Article 5.')

      click('button', text: 'load 4 more')

      wait_for_gql('apps/mobile/modules/ticket/graphql/queries/ticket/articles.graphql')

      (1..4).each do |number|
        expect(page).to have_text(articles[number].body, count: 1)
      end

      expect(page).to have_no_text('load')
    end
  end
end

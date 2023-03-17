# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Search', app: :mobile, authenticated_as: :user, type: :system do
  context 'when searching as customer', authenticated_as: :customer do
    let(:organization) { create(:organization) }
    let(:customer)     { create(:customer, organization: organization) }

    it 'opens tickets search page by default, since customer doesn\'t have access to others' do
      visit '/search'
      expect_current_route('/search/ticket')
    end

    it 'can search tickets' do
      create(:ticket, title: 'test ticket', customer_id: customer.id).tap do |ticket|
        create(:ticket_article, ticket: ticket)
      end
      create(:ticket, title: 'other ticket', customer_id: customer.id).tap do |ticket|
        create(:ticket_article, ticket: ticket)
      end

      visit '/search/ticket'

      fill_in placeholder: 'Search…', with: 'test'

      wait_for_gql('apps/mobile/pages/search/graphql/queries/searchOverview.graphql')

      expect(page).to have_text('test ticket')
      expect(page).to have_no_text('other ticket')
    end

    it 'can\'t search users' do
      visit '/search/user'

      expect(page).to have_no_text('User')
    end

    it 'can\'t search organizations' do
      visit '/search/organization'

      expect(page).to have_no_text('Organization')
    end
  end

  context 'when searching as agent', authenticated_as: :agent do
    let(:organization) { create(:organization) }
    let(:ticket1) do
      create(:ticket, title: 'test ticket', organization_id: organization.id).tap do |ticket|
        create(:ticket_article, ticket: ticket)
      end
    end
    let(:ticket2) do
      create(:ticket, title: 'other ticket', organization_id: organization.id).tap do |ticket|
        create(:ticket_article, ticket: ticket)
      end
    end
    let(:agent) { create(:agent, organization: organization, groups: [ticket1.group, ticket2.group]) }

    it 'can search tickets' do
      visit '/search/ticket'

      fill_in placeholder: 'Search…', with: 'test'

      wait_for_gql('apps/mobile/pages/search/graphql/queries/searchOverview.graphql')

      expect(page).to have_text('test ticket')
      expect(page).to have_no_text('other ticket')
    end

    it 'can search users' do
      create(:customer, firstname: 'test', lastname: 'customer')
      create(:customer, firstname: 'other', lastname: 'customer')

      visit '/search/user'

      fill_in placeholder: 'Search…', with: 'test'

      wait_for_gql('apps/mobile/pages/search/graphql/queries/searchOverview.graphql')

      expect(page).to have_text('test customer')
      expect(page).to have_no_text('other customer')
    end

    it 'can search organizations' do
      create(:organization, name: 'test organization')
      create(:organization, name: 'other organization')

      visit '/search/organization'

      fill_in placeholder: 'Search…', with: 'test'

      wait_for_gql('apps/mobile/pages/search/graphql/queries/searchOverview.graphql')

      expect(page).to have_text('test organization')
      expect(page).to have_no_text('other organization')
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Tickets > Hide certain columns', app: :mobile, type: :system do
  let(:organization)        { create(:organization) }
  let(:user)                { create(:customer, organization: organization) }
  let(:group)               { create(:group) }
  let(:agent)               { create(:agent, groups: [group]) }

  before do
    create(:ticket, customer: user, organization: organization, group: group, created_by_id: user.id, state: Ticket::State.lookup(name: 'open'), priority: Ticket::Priority.lookup(name: '1 low'))

    # testing agent on "open tickets"
    Overview.find_by(link: 'all_open').update!(
      view: {
        s:                 %w[title priority],
        view_mode_default: 's',
      },
    )
    Overview.find_by(link: 'all_unassigned').update!(
      view: {
        s:                 %w[title],
        view_mode_default: 's',
      },
    )
    # testing customer on "my tickets"
    Overview.find_by(link: 'my_tickets').update!(
      view: {
        s:                 %w[title priority],
        view_mode_default: 's',
      },
    )
    Overview.find_by(link: 'my_organization_tickets').update!(
      view: {
        s:                 %w[title],
        view_mode_default: 's',
      },
    )
  end

  context 'when user is agent', authenticated_as: :agent do
    it 'can see columns, when defined in viewColumns, because user is agent' do
      visit '/tickets/view/all_open'
      expect(page).to have_text('1 LOW')
    end

    it 'can see columns, when not defined in viewColumns, because user is agent' do
      visit '/tickets/view/all_unassigned'
      expect(page).to have_text('1 LOW')
    end
  end

  context 'when user is customer', authenticated_as: :user do
    it 'can see columns because they are defined in viewColumns' do
      visit '/tickets/view/my_tickets'
      expect(page).to have_text('1 LOW')
    end

    it 'cannot see columns for overview, because they are not defined in viewColumns' do
      visit '/tickets/view/my_organization_tickets'
      expect(page).to have_no_text('1 LOW')
    end
  end
end

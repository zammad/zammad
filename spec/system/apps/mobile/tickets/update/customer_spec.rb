# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Update Customer', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group: group) }

  before do
    visit "/tickets/#{ticket.id}"
    click_button 'Show ticket actions'
    click_button 'Change customer'
  end

  context 'with a single-organization customer' do
    let(:organization) { create(:organization) }
    let(:customer) { create(:customer, organization: organization) }

    it 'allows selecting customer' do
      find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
      click_button 'Save'

      wait.until do
        ticket.reload.customer == customer && ticket.organization = organization
      end
    end
  end

  context 'with a multi-organization customer' do
    let(:organization) { create(:organization) }
    let(:secondary_orgs) { create_list(:organization, 2) }
    let(:customer)       { create(:customer, organization: organization, organizations: secondary_orgs) }

    it 'allows selecting customer' do
      find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
      find_autocomplete('Organization').search_for_option(secondary_orgs.last.name)
      click_button 'Save'

      wait.until do
        ticket.reload.customer == customer && ticket.organization == secondary_orgs.last
      end
    end
  end

end

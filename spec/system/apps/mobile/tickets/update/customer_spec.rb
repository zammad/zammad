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

  def select_entry(type, search_text)
    find('label', text: type).sibling('.formkit-inner').click
    find('[role="searchbox"]').fill_in(with: search_text)
    find('[role="option"]', text: search_text).click
  end

  context 'with a single-organization customer' do
    let(:organization) { create(:organization) }
    let(:customer) { create(:customer, organization: organization) }

    it 'allows selecting customer' do
      select_entry('Customer', customer.firstname)
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
      select_entry('Customer', customer.firstname)
      select_entry('Organization', secondary_orgs.last.name)
      click_button 'Save'

      wait.until do
        ticket.reload.customer == customer && ticket.organization == secondary_orgs.last
      end
    end
  end

end

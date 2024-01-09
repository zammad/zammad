# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Sidebar > Customer', :aggregate_failures, type: :system do
  let(:primary_organization)    { create(:organization) }
  let(:secondary_organizations) { create_list(:organization, 3) }
  let(:customer)                { create(:customer, organization: primary_organization, organizations: secondary_organizations) }
  let(:ticket)                  { create(:ticket, group: Group.find_by(name: 'Users'), customer: customer) }

  context "when using the sidebar to get current customer's information" do
    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    context 'when changing the customer/organization' do
      it 'shows the organization field with all possible organizations' do
        click '.tabsSidebar-tab[data-tab=customer]'
        click '#userAction'
        click_on 'Change Customer'
        modal_ready

        in_modal do
          find('[name="customer_id"] ~ .user-select.token-input').fill_in with: customer.firstname

          expect(page).to have_css('ul.recipientList > li.recipientList-entry', minimum: 1)

          first('.recipientList-entry.js-object').click
          expect(page).to have_css('[name="organization_id"]', visible: :all)

          find('[data-attribute-name="organization_id"] .js-input').click

          expect(page).to have_css('ul.js-optionsList > li.js-option', count: 4)
        end
      end
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# TODO: Check why editing user's secondary organizations is not working.

RSpec.describe 'Mobile > Search > User > Edit', app: :mobile, authenticated_as: :authenticate, db_strategy: :reset, type: :system do
  let(:primary_organization)    { create(:organization) }
  let(:secondary_organizations) { create_list(:organization, 4) }
  let(:customer)                { create(:customer, organization: primary_organization, organizations: secondary_organizations, address: 'Berlin') }
  let(:group)                   { create(:group) }
  let(:ticket)                  { create(:ticket, customer: customer, group: group) }
  let(:agent)                   { create(:agent, groups: [group]) }
  let(:closed_tickets)          { create_list(:ticket, 2, customer: customer, group: group, state: Ticket::State.find_by(name: 'closed')) }

  def authenticate
    ticket
    closed_tickets
    create(:object_manager_attribute_text, object_name: 'User', name: 'text_attribute', display: 'Text Attribute', screens: { edit: { '-all-' => { shown: true, required: false } }, view: { '-all-' => { shown: true, required: false } } })
    ObjectManager::Attribute.migration_execute
    agent
  end

  before do
    visit '/search/user'

    fill_in placeholder: 'Search…', with: customer.email

    wait_for_gql('apps/mobile/pages/search/graphql/queries/searchOverview.graphql')

    click '[role="tabpanel"]', text: customer.fullname
  end

  it 'shows user data' do
    expect(find("[role=\"img\"][aria-label=\"Avatar (#{customer.fullname})\"]")).to have_text(customer.firstname[0].upcase + customer.lastname[0].upcase)
    expect(page).to have_text(customer.fullname)
    expect(page).to have_css('a', text: primary_organization.name)
    expect(find('section', text: 'Email')).to have_text(customer.email)
    expect(find('section', text: 'Address')).to have_text(customer.address)
    expect(page).to have_no_css('section', text: 'Text Attribute')

    click_button('Show 1 more')

    wait_for_gql('apps/mobile/entities/user/graphql/queries/user.graphql', number: 2)

    secondary_organizations.each do |organization|
      expect(page).to have_text(organization.name)
    end

    expect(find_all('[data-test-id="section-menu-item"]')[0]).to have_text("open\n1")
    expect(find_all('[data-test-id="section-menu-item"]')[1]).to have_text("closed\n2")
  end

  it 'supports editing user data' do
    click_button('Edit')

    wait_for_form_to_settle('user-edit')

    within_form(form_updater_gql_number: 1) do
      find_input('Text Attribute').type('foobar')
      find_input('First name').type('Foo')
      find_input('Last name').type('Bar')
      find_input('Address').type('München')
      find_autocomplete('Organization').search_for_option(secondary_organizations.first.name)

      # # Despite the name of the action, the following DESELECTS all secondary organizations for the customer.
      # #   This works because all these values are already selected in the field.
      # find_autocomplete('Secondary organizations').select_options(secondary_organizations.map { |organization| organization.name })
    end

    click_button('Save')

    wait_for_gql('shared/graphql/subscriptions/userUpdates.graphql')

    expect(find('[role="img"][aria-label="Avatar (Foo Bar)"]')).to have_text('FB')
    expect(page).to have_text('Foo Bar')
    expect(page).to have_css('a', text: secondary_organizations.first.name)
    expect(find('section', text: 'Address')).to have_text('München')
    expect(find('section', text: 'Text Attribute')).to have_text('foobar')

    # expect(page).to have_no_text('Secondary organizations')

    # secondary_organizations.each do |organization|
    #   expect(page).to have_no_text(organization.name)
    # end

    expect(customer.reload).to have_attributes(firstname: 'Foo', lastname: 'Bar', text_attribute: 'foobar', address: 'München')
  end
end

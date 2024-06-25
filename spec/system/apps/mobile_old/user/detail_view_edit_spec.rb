# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile_old/examples/core_workflow_examples'

RSpec.describe 'Mobile > Search > User > Edit', app: :mobile, authenticated_as: :authenticate, type: :system do
  let(:user)   { create(:customer, :with_org, address: 'Berlin') }
  let(:group)  { create(:group) }
  let(:ticket) { create(:ticket, customer: user, group: group) }
  let(:agent)  { create(:agent, groups: [group]) }

  def authenticate
    agent
  end

  def open_user
    visit "/users/#{user.id}"
    wait_for_gql('shared/entities/user/graphql/queries/user.graphql')
  end

  def open_user_edit
    open_user
    click('button', text: 'Edit')
    wait_for_form_to_settle('user-edit')
  end

  context 'when opening via search' do
    before do
      visit '/search/user'
      fill_in placeholder: 'Search…', with: user.email
      wait_for_gql('apps/mobile/pages/search/graphql/queries/searchOverview.graphql')
      click '[role="tabpanel"]', text: user.fullname
    end

    it 'shows user details' do
      expect(page).to have_current_path("/mobile/users/#{user.id}")
    end
  end

  context 'with custom attribute', db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_text, object_name: 'User', name: 'text_attribute', display: 'Text Attribute', screens: { edit: { '-all-' => { shown: true, required: false } }, view: { '-all-' => { shown: true, required: false } } })
      ObjectManager::Attribute.migration_execute
      agent
    end

    it 'show attribute only when value exists' do
      open_user

      expect(page).to have_no_css('section', text: 'Text Attribute')

      click_on('Edit')

      wait_for_form_to_settle('user-edit')

      within_form(form_updater_gql_number: 1) do
        find_input('Text Attribute').type('foobar')
      end

      click_on('Save')

      wait_for_gql('shared/graphql/subscriptions/userUpdates.graphql')

      expect(find('section', text: 'Text Attribute')).to have_text('foobar')
    end
  end

  context 'with basic attributes' do
    let(:closed_tickets) do
      create_list(:ticket, 2, customer: user, group: group, state: Ticket::State.find_by(name: 'closed'))
    end

    before do
      ticket
      closed_tickets

      open_user
    end

    it 'shows basic data' do
      expect(find("[role=\"img\"][aria-label=\"Avatar (#{user.fullname})\"]")).to have_text(user.firstname[0].upcase + user.lastname[0].upcase)
      expect(page).to have_text(user.fullname)
      expect(page).to have_css('a', text: user.organization.name)
      expect(find('section', text: 'Email')).to have_text(user.email)
      expect(find('section', text: 'Address')).to have_text(user.address)
    end

    it 'shows links to open and closed issues' do
      expect(find_all('[data-test-id="section-menu-item"]'))
        .to contain_exactly(have_text("open\n1"), have_text("closed\n2"))
    end
  end

  context 'with secondary organizations' do
    let(:organizations) { create_list(:organization, 4) }

    it 'shows secondary organizations' do
      user.update! organizations: organizations

      open_user

      expect(page)
        .to have_multiple_texts(organizations[0..2].map(&:name))
        .and(have_no_text(organizations.last.name))

      click_on('Show 1 more')

      wait_for_gql('shared/entities/user/graphql/queries/user.graphql', number: 2)

      expect(page).to have_multiple_texts(organizations.map(&:name))
    end

    it 'adds secondary organizations' do
      open_user_edit

      find_autocomplete('Secondary organizations')
        .search_for_options(organizations[0..1].map(&:name))

      click_on 'Save'

      expect(page)
        .to have_multiple_texts(organizations[0..1].map(&:name))
    end
  end

  context 'when editing' do
    before do
      open_user_edit
    end

    let(:organization) { create(:organization) }

    shared_examples 'editing user data' do
      it 'supports editing user data' do
        within_form(form_updater_gql_number: 1) do
          find_input('First name').type('Foo')
          find_input('Last name').type('Bar')
          find_input('Address').type('München')
          find_autocomplete('Organization').search_for_option(organization.name)
        end

        click_on('Save')

        wait_for_gql('shared/graphql/subscriptions/userUpdates.graphql')

        expect(find('[role="img"][aria-label="Avatar (Foo Bar)"]')).to have_text('FB')
        expect(page).to have_text('Foo Bar')
        expect(page).to have_css('a', text: organization.name)
        expect(find('section', text: 'Address')).to have_text('München')

        expect(user.reload).to have_attributes(firstname: 'Foo', lastname: 'Bar', address: 'München')
      end
    end

    it_behaves_like 'editing user data'

    it 'has an always enabled cancel button' do
      find_button('Cancel').click

      expect(page).to have_no_css('[role=dialog]')
    end

    it 'shows a confirmation dialog when leaving the screen' do
      within_form(form_updater_gql_number: 1) do
        find_input('Address').type('foobar')
      end

      find_button('Cancel').click

      within '[role=alert]' do
        expect(page).to have_text('Are you sure? You have unsaved changes that will get lost.')
      end
    end

    context 'when user is email-less' do
      let(:user) { create(:customer, :without_email) }

      it 'updates User record' do
        within_form(form_updater_gql_number: 1) do
          find_input('First name').type('No Email')

          click_on('Save')

          wait_for_gql('shared/graphql/subscriptions/userUpdates.graphql')

          expect(user.reload).to have_attributes(firstname: 'No Email')
        end
      end
    end

    context 'with admin privileges (#5066)' do
      let(:agent) { create(:admin) }

      it_behaves_like 'editing user data'
    end
  end

  describe 'Core Workflow' do
    include_examples 'mobile app: core workflow' do
      let(:object_name)             { 'User' }
      let(:form_updater_gql_number) { 1 }
      let(:before_it) do
        lambda {
          open_user

          click('button', text: 'Edit')
          wait_for_form_to_settle('user-edit')
        }
      end
    end
  end
end

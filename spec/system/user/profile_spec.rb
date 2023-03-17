# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'system/examples/core_workflow_examples'
require 'system/examples/text_modules_examples'

RSpec.describe 'User Profile', type: :system do
  let(:organizations) { create_list(:organization, 20) }
  let(:customer)      { create(:customer, organization: organizations[0], organizations: organizations[1..]) }

  it 'does show the edit link' do
    visit "#user/profile/#{customer.id}"
    click '#userAction label'
    click_link 'Edit'
    modal_ready
  end

  describe 'object manager attributes maxlength', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      customer
      create(:object_manager_attribute_text, :required_screen, object_name: 'User', name: 'maxtest', display: 'maxtest', data_option: {
               'type'      => 'text',
               'maxlength' => 3,
               'null'      => true,
               'translate' => false,
               'default'   => '',
               'options'   => {},
               'relation'  => '',
             })
      ObjectManager::Attribute.migration_execute
      true
    end

    it 'checks ticket create' do
      visit "#user/profile/#{customer.id}"
      within(:active_content) do
        page.find('.profile .js-action').click
        page.find('.profile li[data-type=edit]').click
        fill_in 'maxtest', with: 'hellu'
        expect(page.find_field('maxtest').value).to eq('hel')
      end
    end
  end

  describe 'Core Workflow' do
    include_examples 'core workflow' do
      let(:object_name) { 'User' }
      let(:before_it) do
        lambda {
          ensure_websocket(check_if_pinged: false) do
            visit "#user/profile/#{customer.id}"
            within(:active_content) do
              page.find('.profile .js-action').click
              page.find('.profile li[data-type=edit]').click
            end
          end
        }
      end
    end
  end

  it 'check that ignored attributes for user popover are not visible' do
    visit '/'

    fill_in id: 'global-search', with: customer.email

    popover_on_hover(find('.nav-tab--search.user'))

    expect(page).to have_css('.popover label', count: 2)
  end

  context 'Assign user to multiple organizations #1573', authenticated_as: :authenticate do
    def authenticate
      customer
      true
    end

    before do
      visit "#user/profile/#{customer.id}"
    end

    it 'shows only first 3 organizations and loads more on demand' do
      expect(page).to have_text(organizations[1].name)
      expect(page).to have_text(organizations[2].name)
      expect(page).to have_no_text(organizations[10].name)

      click '.js-showMoreOrganizations a'

      expect(page).to have_text(organizations[10].name)
    end
  end

  context 'when ticket changes in user profile', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, title: SecureRandom.uuid, customer: create(:customer, :with_org), group: Group.first) }

    def authenticate
      ticket
      true
    end

    before do
      visit "#user/profile/#{ticket.customer.id}"
    end

    it 'does update when ticket changes' do
      expect(page).to have_text(ticket.title)
      ticket.update(title: SecureRandom.uuid)
      expect(page).to have_text(ticket.title)
    end
  end

  describe 'Missing secondary organizations in user profile after refreshing with many secondary organizations. #4331' do
    before do
      visit "#user/profile/#{customer.id}"
      page.find('.profile .js-action').click
      page.find('.profile li[data-type=edit]').click
    end

    it 'does show all secondary organizations on edit' do
      tokens = page.all('div[data-attribute-name="organization_ids"] .token')
      expect(tokens.count).to eq(19)
    end
  end
end

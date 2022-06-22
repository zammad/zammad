# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'system/examples/core_workflow_examples'
require 'system/examples/text_modules_examples'

RSpec.describe 'User Profile', type: :system do
  let(:organizations) { create_list(:organization, 20) }
  let(:customer)      { create(:customer, organization: organizations[0], organizations: organizations[1..]) }

  describe 'object manager attributes maxlength', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      customer
      create :object_manager_attribute_text, object_name: 'User', name: 'maxtest', display: 'maxtest', screens: attributes_for(:required_screen), data_option: {
        'type'      => 'text',
        'maxlength' => 3,
        'null'      => true,
        'translate' => false,
        'default'   => '',
        'options'   => {},
        'relation'  => '',
      }
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
end

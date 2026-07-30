# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Object manager attributes', type: :system do
  context 'object manager attribute permission view' do
    let!(:group_users) { Group.find_by(name: 'Users') }

    shared_examples 'shows attributes and values for agent view and editable' do
      it 'shows attributes and values for agent view and editable', authenticated_as: :current_user do
        visit "ticket/zoom/#{ticket.id}"
        refresh # refresh to have assets generated for ticket

        expect(page).to have_select('state_id', options: ['new', 'open', 'pending reminder', 'pending close', 'closed'])
        expect(page).to have_select('priority_id')
        expect(page).to have_select('owner_id')
        expect(page).to have_css('div.tabsSidebar-tab[data-tab=customer]')
      end
    end

    shared_examples 'shows attributes and values for agent view but disabled' do
      it 'shows attributes and values for agent view but disabled', authenticated_as: :current_user do
        visit "ticket/zoom/#{ticket.id}"
        refresh # refresh to have assets generated for ticket

        expect(page).to have_select('state_id', disabled: true)
        expect(page).to have_select('priority_id', disabled: true)
        expect(page).to have_select('owner_id', disabled: true)
        expect(page).to have_css('div.tabsSidebar-tab[data-tab=customer]')
      end
    end

    shared_examples 'shows attributes and values for customer view' do
      it 'shows attributes and values for customer view', authenticated_as: :current_user do
        visit "ticket/zoom/#{ticket.id}"
        refresh # refresh to have assets generated for ticket

        expect(page).to have_select('state_id', options: %w[new open closed])
        expect(page).to have_no_select('priority_id')
        expect(page).to have_no_select('owner_id')
        expect(page).to have_no_css('div.tabsSidebar-tab[data-tab=customer]')
      end
    end

    context 'as customer' do
      let!(:current_user) { create(:customer) }
      let(:ticket)        { create(:ticket, customer: current_user) }

      include_examples 'shows attributes and values for customer view'
    end

    context 'as agent with full permissions' do
      let(:current_user) { create(:agent, groups: [ group_users ]) }
      let(:ticket) { create(:ticket, group: group_users) }

      include_examples 'shows attributes and values for agent view and editable'
    end

    context 'as agent with change permissions' do
      let!(:current_user) { create(:agent) }
      let(:ticket) { create(:ticket, group: group_users) }

      before do
        current_user.group_names_access_map = {
          group_users.name => %w[read change],
        }
      end

      include_examples 'shows attributes and values for agent view and editable'
    end

    context 'as agent with read permissions' do
      let!(:current_user) { create(:agent) }
      let(:ticket) { create(:ticket, group: group_users) }

      before do
        current_user.group_names_access_map = {
          group_users.name => 'read',
        }
      end

      include_examples 'shows attributes and values for agent view but disabled'
    end

    context 'as agent+customer with full permissions' do
      let!(:current_user) { create(:agent_and_customer, groups: [ group_users ]) }

      context 'normal ticket' do
        let(:ticket) { create(:ticket, group: group_users) }

        include_examples 'shows attributes and values for agent view and editable'
      end

      context 'ticket where current_user is also customer' do
        let(:ticket) { create(:ticket, customer: current_user, group: group_users) }

        include_examples 'shows attributes and values for agent view and editable'
      end
    end

    context 'as agent+customer with change permissions' do
      let!(:current_user) { create(:agent_and_customer) }

      before do
        current_user.group_names_access_map = {
          group_users.name => %w[read change],
        }
      end

      context 'normal ticket' do
        let(:ticket) { create(:ticket, group: group_users) }

        include_examples 'shows attributes and values for agent view and editable'
      end

      context 'ticket where current_user is also customer' do
        let(:ticket) { create(:ticket, customer: current_user, group: group_users) }

        include_examples 'shows attributes and values for agent view and editable'
      end
    end

    context 'as agent+customer with read permissions' do
      let!(:current_user) { create(:agent_and_customer) }

      before do
        current_user.group_names_access_map = {
          group_users.name => 'read',
        }
      end

      context 'normal ticket' do
        let(:ticket) { create(:ticket, group: group_users) }

        include_examples 'shows attributes and values for agent view but disabled'
      end

      context 'ticket where current_user is also customer' do
        let(:ticket) { create(:ticket, customer: current_user, group: group_users) }

        include_examples 'shows attributes and values for agent view but disabled'
      end
    end

    context 'as agent+customer but only customer for the ticket (no agent access)' do
      let!(:current_user) { create(:agent_and_customer) }
      let(:ticket)        { create(:ticket, customer: current_user) }

      include_examples 'shows attributes and values for customer view'
    end
  end

  describe 'object manager attributes maxlength', authenticated_as: :authenticate, db_strategy: :reset do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      ticket
      create(:object_manager_attribute_text, :required_screen, name: 'maxtest', display: 'maxtest', data_option: {
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

    it 'checks ticket zoom' do
      visit "ticket/zoom/#{ticket.id}"
      within(:active_content) do
        fill_in 'maxtest', with: 'hellu'
        expect(page.find_field('maxtest').value).to eq('hel')
      end
    end
  end

  describe 'Multiselect marked as dirty', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:ticket)     { create(:ticket, group: Group.find_by(name: 'Users'), field_name => []) }

    def authenticate
      create(:object_manager_attribute_multiselect, name: field_name, display: field_name, screens: {
               'edit' => {
                 'ticket.agent' => {
                   'shown'    => true,
                   'required' => false,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute
      ticket
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does show values properly and can save values also' do
      expect(page).to have_no_css('.attributeBar-reset')
    end
  end

  describe 'Multiselect displaying and saving', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:ticket)     { create(:ticket, group: Group.find_by(name: 'Users'), field_name => %w[value_2 value_3]) }
    let(:options_hash) do
      {
        'value_1' => 'value_1',
        'value_2' => 'value_2',
        'value_3' => 'value_3',
      }
    end
    let(:data_option) { { options: options_hash, default: [] } }

    def authenticate
      create(:object_manager_attribute_multiselect, name: field_name, display: field_name, data_option: data_option, screens: {
               'edit' => {
                 'ticket.agent' => {
                   'shown'    => true,
                   'required' => false,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute
      ticket
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    def multiselect_field
      page.find("select[name='#{field_name}']")
    end

    def multiselect_value
      multiselect_field.value
    end

    def multiselect_set(values)
      multiselect_unset_all
      values = Array(values)
      values.each do |value|
        multiselect_field.select(value)
        expect(multiselect_value).to include(value)
      end
    end

    def multiselect_unset_all
      values = multiselect_value
      values.each do |value|
        multiselect_field.unselect(value)
        expect(multiselect_value).to not_include(value)
      end
    end

    context 'when showing and saving values' do
      it 'shows saved values properly' do
        expect(multiselect_value).to eq(%w[value_2 value_3])
      end

      it 'saves multiple values properly' do
        multiselect_set(%w[value_1 value_2])
        click '.js-submit'

        expect(ticket.reload[field_name]).to eq(%w[value_1 value_2])
      end

      it 'saves single value properly' do
        multiselect_set(%w[value_1])
        click '.js-submit'

        expect(ticket.reload[field_name]).to eq(%w[value_1])
      end

      it 'removes saved values properly' do
        multiselect_unset_all
        click '.js-submit'

        expect(ticket.reload[field_name]).to be_empty
      end
    end
  end

  describe 'Inconsistent group search when selected value is in deeper levels of a sub group #5707', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: create(:group, name: 'TreeB::AAA::BBB::CCC')) }

    def authenticate
      create(:group, name: 'TreeA')
      create(:group, name: 'TreeA::AAA')
      create(:group, name: 'TreeA::AAA::BBB')
      create(:group, name: 'TreeA::AAA::BBB::CCC')
      create(:group, name: 'TreeB')
      create(:group, name: 'TreeB::AAA')
      create(:group, name: 'TreeB::AAA::BBB')
      ticket
      create(:agent, groups: Group.all)
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does show the right group level' do
      page.find("div[data-attribute-name='group_id']").click
      wait.until { page.all('span.searchableSelect-option-text').none? { |element| element.text.include?('TreeA') } }
    end
  end
end

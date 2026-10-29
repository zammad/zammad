# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/core_workflow_examples'

RSpec.describe 'Ticket zoom > Core Workflow', type: :system do
  include_examples 'core workflow' do
    let(:ticket)      { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:object_name) { 'Ticket' }
    let(:before_it) do
      lambda {
        ensure_websocket(check_if_pinged: false) do
          visit "#ticket/zoom/#{ticket.id}"
        end
      }
    end
  end

  describe 'Core Workflow: Show hidden attributes on group selection (ticket edit) #3739', authenticated_as: :authenticate, db_strategy: :reset do
    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create(:object_manager_attribute_text, name: field_name, display: field_name, screens: {
               'edit' => {
                 'ticket.agent' => {
                   'shown'    => false,
                   'required' => false,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    context 'when field visible' do
      let(:workflow) do
        create(:core_workflow,
               object:  'Ticket',
               perform: { "ticket.#{field_name}" => { 'operator' => 'show', 'show' => 'true' } })
      end

      def authenticate
        field
        workflow
        true
      end

      it 'does show up the field' do
        expect(page).to have_css("div[data-attribute-name='#{field_name}']")
      end
    end

    context 'when field hidden' do
      def authenticate
        field
        true
      end

      it 'does not show the field' do
        expect(page).to have_css("div[data-attribute-name='#{field_name}'].is-hidden", visible: :hidden)
      end
    end
  end

  describe 'Unable to close tickets in certran cases if core workflow is used #3710', authenticated_as: :authenticate, db_strategy: :reset do
    let!(:ticket)    { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create(:object_manager_attribute_text, name: field_name, display: field_name, screens: {
               'edit' => {
                 'ticket.agent' => {
                   'shown'    => false,
                   'required' => false,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute
    end
    let(:workflow) do
      create(:core_workflow,
             object:  'Ticket',
             perform: { "ticket.#{field_name}" => { 'operator' => 'set_mandatory', 'set_mandatory' => 'true' } })
    end

    def authenticate
      field
      workflow
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does save the ticket because the field is mandatory but hidden' do
      admin = User.find_by(email: 'admin@example.com')
      select admin.fullname, from: 'Owner'
      find('.js-submit').click
      expect(ticket.reload.owner_id).to eq(admin.id)
    end
  end

  describe "escaped 'Set fixed' workflows don't refresh set values on active ticket sessions #3757", authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users'), field_name => false) }

    def authenticate
      workflow
      create(:object_manager_attribute_boolean, :required_screen, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
      ticket
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    context 'when operator set_fixed_to' do
      let(:workflow) do
        create(:core_workflow,
               object:  'Ticket',
               perform: { "ticket.#{field_name}" => { 'operator' => 'set_fixed_to', 'set_fixed_to' => ['false'] } })
      end

      context 'when saved value is removed by set_fixed_to operator' do
        it 'does show up the saved value if it would not be possible because of the restriction' do
          expect(page.find("select[name='#{field_name}']").value).to eq('false')
          ticket.update(field_name => true)
          wait.until { page.find("select[name='#{field_name}']").value == 'true' }
          expect(page.find("select[name='#{field_name}']").value).to eq('true')
        end
      end
    end

    context 'when operator remove_option' do
      let(:workflow) do
        create(:core_workflow,
               object:  'Ticket',
               perform: { "ticket.#{field_name}" => { 'operator' => 'remove_option', 'remove_option' => ['true'] } })
      end

      context 'when saved value is removed by set_fixed_to operator' do
        it 'does show up the saved value if it would not be possible because of the restriction' do
          expect(page.find("select[name='#{field_name}']").value).to eq('false')
          ticket.update(field_name => true)
          wait.until { page.find("select[name='#{field_name}']").value == 'true' }
          expect(page.find("select[name='#{field_name}']").value).to eq('true')
        end
      end
    end
  end

  describe 'Owner should get cleared if not listed in changed group #3818', authenticated_as: :authenticate do
    let(:group1) { create(:group) }
    let(:group2) { create(:group) }
    let(:agent1) { create(:agent) }
    let(:agent2) { create(:agent) }
    let(:ticket) { create(:ticket, group: group1, owner: agent1) }

    def authenticate
      agent1.group_names_access_map = {
        group1.name => 'full',
        group2.name => %w[read change overview]
      }
      agent2.group_names_access_map = {
        group1.name => 'full',
        group2.name => 'full',
      }
      agent1
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does clear agent1 on select of group 2' do
      set_tree_select_value('group_id', group2.name)
      wait.until { page.find('select[name=owner_id]').value != agent1.id.to_s }
      expect(page.find('select[name=owner_id]').value).to eq('')
      expect(page.all('select[name=owner_id] option').map(&:value)).not_to include(agent1.id.to_s)
      expect(page.all('select[name=owner_id] option').map(&:value)).to include(agent2.id.to_s)
    end
  end

  describe 'Not displayed fields should not impact the edit screen #3819', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      create(:object_manager_attribute_boolean, default: nil, screens: {
               edit: {
                 'ticket.agent' => {
                   shown:    false,
                   required: false,
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

    it 'does not show any changes for the field because it has no value and because it is not shown it should also not show the ticket as changed' do
      expect(page).to have_css(".content.active select[name='state_id']")
      wait.until { page.evaluate_script("Object.values(App.Delay._all()).every(function(level) { return !('ticket-zoom-form-update' in level) })") }
      await_empty_ajax_queue
      expect(page).to have_no_css('.js-reset')
    end
  end

  describe 'Changing ticket status from "new" to any other status always results in uncommited status "closed" #3880', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.priority_id': {
                 operator: 'is',
                 value:    [ Ticket::Priority.find_by(name: '3 high').id.to_s ],
               },
             },
             perform:            { 'ticket.state_id' => { operator: 'remove_option', remove_option: [ Ticket::State.find_by(name: 'pending reminder').id.to_s ] } })
    end

    def authenticate
      workflow
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does switch back to the saved value in the ticket instead of the first value of the dropdown' do
      page.select 'pending reminder', from: 'state_id'
      page.select '3 high', from: 'priority_id'
      expect(page).to have_select('state_id', selected: 'new')
    end
  end

  describe 'Changing ticket status resets state to the first dropdown option when the cached object is stale #3880', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      ticket
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'keeps the real ticket state instead of resetting to the first option' do
      expect(page).to have_select('state_id', selected: 'new')

      # Simulate a concurrent update whose websocket push has not yet reached
      # the client (e.g. behind a reverse proxy), so the cached ticket object
      # stays stale while the backend already sees the new state.
      Ticket.where(id: ticket.id).update_all(state_id: Ticket::State.find_by(name: 'open').id, updated_at: Time.current)

      # Trigger a Core Workflow run without touching the state field.
      page.select '3 high', from: 'priority_id'

      expect(page).to have_select('state_id', selected: 'open')
    end
  end

  describe 'Ticket state resets to the first dropdown option when the sidebar renders with stale Core Workflow data #3880', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users'), state: Ticket::State.find_by(name: 'open')) }

    def authenticate
      ticket
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'keeps the saved ticket state when discarding changes' do
      expect(page).to have_select('state_id', selected: 'open')

      page.select '3 high', from: 'priority_id'
      expect(page).to have_css('.js-reset:not(.hide)')

      # Simulate a concurrent update (e.g. by a trigger) to a state outside of the
      # agent edit filter, which reaches the client before the sidebar received
      # new Core Workflow data for it.
      Ticket.where(id: ticket.id).update_all(state_id: Ticket::State.find_by(name: 'new').id, updated_at: Time.current)
      page.execute_script("App.Collection.loadAssets(#{ticket.reload.assets({}).to_json}); $('.js-reset').trigger('click')")

      expect(page).to have_select('state_id', selected: 'new')
      expect(page).to have_no_css('.sidebar[data-tab="ticket"] .form-group.is-changed')
    end
  end
end

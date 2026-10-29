# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/core_workflow_examples'

RSpec.describe 'Ticket create > Core Workflow', type: :system do
  include_examples 'core workflow' do
    let(:object_name) { 'Ticket' }
    let(:before_it) do
      lambda {
        ensure_websocket(check_if_pinged: false) do
          visit 'ticket/create'
        end
      }
    end
  end

  describe 'It should be possible to show attributes which are configured shown false #3726', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create(:object_manager_attribute_text, name: field_name, display: field_name, screens: {
               'create_middle' => {
                 'ticket.agent' => {
                   'shown'    => false,
                   'required' => false,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute
    end

    before do
      visit 'ticket/create'
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
        expect(page).to have_css("div[data-attribute-name='#{field_name}'].is-hidden.is-removed", visible: :hidden)
      end
    end
  end

  describe 'Support workflow mechanism to do pending reminder state hide pending time use case #3790', authenticated_as: :authenticate do
    let(:template) { create(:template, :dummy_data) }

    def add_state
      Ticket::State.create_or_update(
        name:              'pending customer feedback',
        state_type:        Ticket::StateType.find_by(name: 'pending reminder'),
        ignore_escalation: true,
        created_by_id:     1,
        updated_by_id:     1,
      )
    end

    def update_screens
      attribute = ObjectManager::Attribute.get(
        object: 'Ticket',
        name:   'state_id',
      )
      attribute.data_option[:filter] = Ticket::State.where(active: true).by_category_ids(:viewable)
      attribute.screens[:create_middle]['ticket.agent'][:filter] = Ticket::State.where(active: true).by_category_ids(:viewable_agent_new)
      attribute.screens[:create_middle]['ticket.customer'][:filter] = Ticket::State.where(active: true).by_category_ids(:viewable_customer_new)
      attribute.screens[:edit]['ticket.agent'][:filter] = Ticket::State.where(active: true).by_category_ids(:viewable_agent_edit)
      attribute.screens[:edit]['ticket.customer'][:filter] = Ticket::State.where(active: true).by_category_ids(:viewable_customer_edit)
      attribute.save!
    end

    def create_flow
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'ticket.state_id'=>{ 'operator' => 'is', 'value' => Ticket::State.find_by(name: 'pending customer feedback').id.to_s } },
             perform:            { 'ticket.pending_time'=> { 'operator' => 'remove', 'remove' => 'true' } })
    end

    def authenticate
      add_state
      update_screens
      create_flow
      template
      true
    end

    before do
      visit 'ticket/create'
      use_template(template)
    end

    it 'does make it possible to create pending states where the pending time is optional and not visible' do
      select 'pending customer feedback', from: 'state_id'
      click '.js-submit'
      expect(page).to have_current_path(%r{ticket/zoom}, url: true)
      expect(Ticket.last.state_id).to eq(Ticket::State.find_by(name: 'pending customer feedback').id)
      expect(Ticket.last.pending_time).to be_nil
    end
  end

  describe 'Tree select value cannot be set to "-" (empty) with Trigger/Scheduler/Core workflow #4024', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create(:object_manager_attribute_tree_select, :required_screen, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
    end
    let(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'ticket.priority_id'=>{ 'operator' => 'is', 'value' => Ticket::Priority.find_by(name: '3 high').id.to_s } },
             perform:            { "ticket.#{field_name}" => { 'operator' => 'select', 'select' => 'Incident' } })
    end
    let(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'ticket.priority_id'=>{ 'operator' => 'is', 'value' => Ticket::Priority.find_by(name: '2 normal').id.to_s } },
             perform:            { "ticket.#{field_name}" => { 'operator' => 'select', 'select' => '' } })
    end

    def authenticate
      field
      workflow
      workflow2
      true
    end

    before do
      visit 'ticket/create'
    end

    it 'does select the field value properly' do
      page.find('[name=priority_id]').select '3 high'
      wait.until { page.find("input[name='#{field_name}']", visible: :all).value == 'Incident' }
      page.find('[name=priority_id]').select '2 normal'
      wait.until { page.find("input[name='#{field_name}']", visible: :all).value == '' }
    end
  end

  describe 'Not possible to select multiple values in a multi-tree select when a workflow with a select action is executed #4465', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:screens) do
      {
        'create_middle' => {
          'ticket.agent' => {
            'shown'    => true,
            'required' => false,
          }
        }
      }
    end

    def authenticate
      create(:object_manager_attribute_multi_tree_select, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute

      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.priority_id': {
                 operator: 'select',
                 select:   [Ticket::Priority.find_by(name: '3 high').id.to_s]
               },
             })

      true
    end

    def multi_tree_select_click(value)
      page.evaluate_script("document.querySelector(\"div[data-attribute-name='#{field_name}'] .js-optionsList li[data-value='#{value}'] .searchableSelect-option-text\").click()")
      await_empty_ajax_queue
    end

    before do
      visit 'ticket/create'
    end

    it 'does not clear the values of the multi tree select' do
      multi_tree_select_click('Incident')
      multi_tree_select_click('Service request')
      multi_tree_select_click('Change request')
      select '1 low', from: 'priority_id'
      select 'pending reminder', from: 'state_id'
      expect(page).to have_css('span.token-label', text: 'Incident')
      expect(page).to have_css('span.token-label', text: 'Service request')
      expect(page).to have_css('span.token-label', text: 'Change request')
    end
  end

  describe 'Support title and body in core workflow actions #4519', authenticated_as: :authenticate do
    let(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'ticket.priority_id'=>{ 'operator' => 'is', 'value' => [Ticket::Priority.find_by(name: '2 normal').id.to_s] } },
             perform:            { 'ticket.title' => { 'operator' => %w[fill_in set_readonly], 'fill_in' => 'title 123', 'set_readonly' => true }, 'ticket.body' => { 'operator' => %w[fill_in set_readonly], 'fill_in' => '<b>text 123</b>', 'set_readonly' => true } })
    end

    context 'when agent' do
      def authenticate
        workflow
        true
      end

      before do
        visit '#ticket/create'
      end

      it 'has core workflow support for title and text' do
        expect(page).to have_css('div[data-attribute-name=title].is-readonly')
        expect(page).to have_css('div[data-attribute-name=body].is-readonly')
        expect(page).to have_field('Title', with: 'title 123')
        expect(page.find('div[data-name=body]')['innerHTML']).to eq('<b>text 123</b>')

        # unset readonly (https://github.com/zammad/zammad/issues/4540)
        select '1 low', from: 'priority_id'
        expect(page).to have_no_css('div[data-attribute-name=title].is-readonly')
        expect(page).to have_no_css('div[data-attribute-name=body].is-readonly')

        # reset readonly
        select '2 normal', from: 'priority_id'
        expect(page).to have_css('div[data-attribute-name=title].is-readonly')
        expect(page).to have_css('div[data-attribute-name=body].is-readonly')
      end
    end

    context 'when customer' do
      def authenticate
        workflow
        create(:customer)
      end

      before do
        visit '#customer_ticket_new'
      end

      it 'has core workflow support for title and text' do
        expect(page).to have_css('div[data-attribute-name=title].is-readonly')
        expect(page).to have_css('div[data-attribute-name=body].is-readonly')
        expect(page).to have_field('Title', with: 'title 123')
        expect(page.find('div[data-name=body]')['innerHTML']).to eq('<b>text 123</b>')
      end
    end
  end

  describe 'CoreWorkflow "fill in empty" fires on non-empty fields during ticket creation when logged in as customer #5004' do
    let(:body_content) { SecureRandom.uuid }
    let(:workflow) do
      create(:core_workflow,
             object:  'Ticket',
             perform: { 'article.body' => { 'operator' => 'fill_in_empty', 'fill_in_empty' => body_content } })
    end

    def setup_workflows
      workflow
    end

    context 'when agent', authenticated_as: :authenticate do
      def authenticate
        setup_workflows
        true
      end

      before do
        visit '#ticket/create'
      end

      it 'does fill the body' do
        check_editor_field_value('body', body_content)
        set_editor_field_value('body', 'new_content')
        check_editor_field_value('body', 'new_content')
        page.find('[name=priority_id]').select '3 high'
        check_editor_field_value('body', 'new_content')
      end
    end

    context 'when customer', authenticated_as: :authenticate do
      def authenticate
        setup_workflows
        create(:customer)
      end

      before do
        visit 'customer_ticket_new'
      end

      it 'does fill the body' do
        check_editor_field_value('body', body_content)
        set_editor_field_value('body', 'new_content')
        check_editor_field_value('body', 'new_content')
        page.find('[name=state_id]').select 'closed'
        check_editor_field_value('body', 'new_content')
      end
    end
  end

  describe 'Core workflow ignores default value if select attribute options are mutated #6370', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.hex(10) }
    let(:screens) do
      {
        create_middle: { '-all-' => { shown: false, required: false } },
        edit:          { '-all-' => { shown: true, required: false } },
      }
    end

    def authenticate
      create(field_factory, object_name: 'Ticket', name: field_name, display: field_name, screens: screens, default: default_value)
      ObjectManager::Attribute.migration_execute

      create(:core_workflow,
             object:  'Ticket',
             perform: {
               "ticket.#{field_name}": {
                 operator:      %w[show remove_option],
                 show:          'true',
                 remove_option: removed_options,
               },
             })

      true
    end

    before do
      visit 'ticket/create'
      wait_for_core_workflow
    end

    context 'with a select attribute' do
      let(:field_factory) { :object_manager_attribute_select }
      let(:default_value) { 'key_2' }

      shared_examples 'preselecting the default value' do |removed_option|
        it 'preselects the default value of the shown field' do
          expect(page).to have_css("select[name='#{field_name}']", visible: :visible)
          expect(page).to have_no_css("select[name='#{field_name}'] option[value='#{removed_option}']")
          expect(find("select[name='#{field_name}']").value).to eq('key_2')
        end
      end

      context 'when a regular option is removed' do
        let(:removed_options) { ['key_3'] }

        include_examples 'preselecting the default value', 'key_3'
      end

      context 'when the empty option is removed' do
        let(:removed_options) { [''] }

        include_examples 'preselecting the default value', ''
      end
    end

    context 'with a multi tree select attribute' do
      let(:field_factory) { :object_manager_attribute_multi_tree_select }
      let(:default_value) { ['Incident', 'Service request'] }

      shared_examples 'preselecting the default values' do |removed_option|
        it 'preselects the default values of the shown field' do
          expect(page).to have_css("div[data-attribute-name='#{field_name}'] input[name='#{field_name}_completion']", visible: :visible)
          expect(page).to have_no_css("div[data-attribute-name='#{field_name}'] .js-optionsList li[data-value='#{removed_option}']", visible: :all) if removed_option
          expect(page).to have_css("div[data-attribute-name='#{field_name}'] span.token-label", text: 'Incident')
          expect(page).to have_css("div[data-attribute-name='#{field_name}'] span.token-label", text: 'Service request')
          expect(find("select[name='#{field_name}']", visible: :all).value).to contain_exactly('Incident', 'Service request')
        end
      end

      context 'when a regular option is removed' do
        let(:removed_options) { ['Change request'] }

        include_examples 'preselecting the default values', 'Change request'
      end

      # tree selects always keep the null option in their list, so only the
      # re-rendering triggered by the option change can be observed here.
      context 'when the empty option is removed' do
        let(:removed_options) { [''] }

        include_examples 'preselecting the default values'
      end
    end
  end
end

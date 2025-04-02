# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe 'CoreWorkflow > Action', mariadb: true, type: :model do
  include_context 'with core workflow base'

  describe '.perform - Stop after match' do
    let(:stop_after_match) { false }

    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
      create(:core_workflow,
             object:           'Ticket',
             perform:          {
               'ticket.priority_id': {
                 operator: 'show',
                 show:     'true'
               },
             },
             stop_after_match: stop_after_match)
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not stop' do
      expect(result[:visibility]['priority_id']).to eq('hide')
    end

    describe 'with stop_after_match' do
      let(:stop_after_match) { true }

      it 'does stop' do
        expect(result[:visibility]['priority_id']).to eq('show')
      end
    end
  end

  describe '.perform - Condition - Custom module' do
    let(:modules) { ['CoreWorkflow::Custom::Testa', 'CoreWorkflow::Custom::Testb', 'CoreWorkflow::Custom::Testc'] }
    let(:custom_class_false) do
      Class.new(CoreWorkflow::Custom::Backend) do
        def selected_attribute_match?
          false
        end
      end
    end
    let(:custom_class_true) do
      Class.new(CoreWorkflow::Custom::Backend) do
        def selected_attribute_match?
          true
        end
      end
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'custom.module': {
                 operator: operator,
                 value:    modules,
               },
             })
    end

    describe 'with "match all modules" false' do
      let(:operator) { 'match all modules' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_false
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    describe 'with "match all modules" true' do
      let(:operator) { 'match all modules' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_true
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_true
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_true
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    describe 'with "match all modules" blank' do
      let(:modules)  { [] }
      let(:operator) { 'match all modules' }

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    describe 'with "match one module" true' do
      let(:operator) { 'match one module' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_true
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    describe 'with "match one module" false' do
      let(:operator) { 'match one module' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_false
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    describe 'with "match one module" blank' do
      let(:modules) { [] }
      let(:operator) { 'match one module' }

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    describe 'with "match no modules" true' do
      let(:operator) { 'match no modules' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_false
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_false
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    describe 'with "match no modules" false' do
      let(:operator) { 'match no modules' }

      before do
        stub_const 'CoreWorkflow::Custom::Testa', custom_class_true
        stub_const 'CoreWorkflow::Custom::Testb', custom_class_true
        stub_const 'CoreWorkflow::Custom::Testc', custom_class_true
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    describe 'with "match no modules" blank' do
      let(:modules) { [] }
      let(:operator) { 'match no modules' }

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe '.perform - Select' do
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
    end
    let!(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is',
                 value:    ticket.group.id.to_s
               },
             },
             perform:            {
               'ticket.owner_id': {
                 operator: 'select',
                 select:   [action_user.id.to_s]
               },
             })
    end

    it 'does match workflows' do
      expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
    end

    it 'does select group' do
      expect(result[:select]['group_id']).to eq(ticket.group.id.to_s)
    end

    it 'does select owner (recursion)' do
      expect(result[:select]['owner_id']).to eq(action_user.id.to_s)
    end

    it 'does rerun 2 times (group select + owner select)' do
      expect(result[:rerun_count]).to eq(2)
    end
  end

  describe '.perform - Auto Select' do
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator:    'auto_select',
                 auto_select: true
               },
             })
    end
    let!(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is',
                 value:    ticket.group.id.to_s
               },
             },
             perform:            {
               'ticket.owner_id': {
                 operator:    'auto_select',
                 auto_select: true
               },
             })
    end

    it 'does match workflows' do
      expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
    end

    it 'does select group' do
      expect(result[:select]['group_id']).to eq(ticket.group.id.to_s)
    end

    it 'does select owner (recursion)' do
      expect(result[:select]['owner_id']).to eq(action_user.id.to_s)
    end

    it 'does rerun 2 times (group select + owner select)' do
      expect(result[:rerun_count]).to eq(2)
    end

    describe 'with owner' do
      let(:payload) do
        base_payload.merge('params' => {
                             'group_id' => ticket.group.id.to_s,
                             'owner_id' => action_user.id.to_s,
                           })
      end

      it 'does not select owner' do
        expect(result[:select]['owner_id']).to be_nil
      end

      it 'does rerun 0 times' do
        expect(result[:rerun_count]).to eq(0)
      end
    end
  end

  describe '.perform - Fill in' do
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
    end
    let!(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is',
                 value:    ticket.group.id.to_s
               },
             },
             perform:            {
               'ticket.title': {
                 operator: 'fill_in',
                 fill_in:  'hello'
               },
             })
    end

    it 'does match workflows' do
      expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
    end

    it 'does select group' do
      expect(result[:select]['group_id']).to eq(ticket.group.id.to_s)
    end

    it 'does fill in title' do
      expect(result[:fill_in]['title']).to eq('hello')
    end

    it 'does rerun 1 time (group select + title fill in)' do
      expect(result[:rerun_count]).to eq(1)
    end
  end

  describe '.perform - Fill in empty' do
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
    end
    let!(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is',
                 value:    ticket.group.id.to_s
               },
             },
             perform:            {
               'ticket.title': {
                 operator:      'fill_in_empty',
                 fill_in_empty: 'hello'
               },
             })
    end

    it 'does match workflows' do
      expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
    end

    it 'does select group' do
      expect(result[:select]['group_id']).to eq(ticket.group.id.to_s)
    end

    it 'does fill in title' do
      expect(result[:fill_in]['title']).to eq('hello')
    end

    it 'does rerun 1 time (group select + title fill in)' do
      expect(result[:rerun_count]).to eq(1)
    end

    describe 'with title' do
      let(:payload) do
        base_payload.merge('params' => {
                             'title' => 'ha!',
                           })
      end

      it 'does not fill in title' do
        expect(result[:fill_in]['title']).to be_nil
      end

      it 'does rerun 1 times (group select)' do
        expect(result[:rerun_count]).to eq(1)
      end
    end
  end

  describe '.perform - Rerun attributes default cache bug' do
    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.owner_id': {
                 operator: 'select',
                 select:   [action_user.id.to_s]
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.owner_id': {
                 operator: 'not_set',
               },
             },
             perform:            {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not hide priority id' do
      expect(result[:visibility]['priority_id']).to eq('show')
    end
  end

  describe '.perform - Clean up params after restrict values removed selected value by set_fixed_to' do
    let(:payload) do
      base_payload.merge('params' => {
                           'owner_id' => action_user.id,
                         })
    end

    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.owner_id': {
                 operator:     'set_fixed_to',
                 set_fixed_to: ['']
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.owner_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not allow owner_id' do
      expect(result[:restrict_values]['owner_id']).not_to include(action_user.id)
    end

    it 'does not hide priority id' do
      expect(result[:visibility]['priority_id']).to eq('show')
    end
  end

  describe '.perform - Clean up params after restrict values removed selected value by remove_option' do
    let(:payload) do
      base_payload.merge('params' => {
                           'owner_id' => action_user.id,
                         })
    end

    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator: 'select',
                 select:   [ticket.group.id.to_s]
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.group_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.owner_id': {
                 operator:      'remove_option',
                 remove_option: [action_user.id]
               },
             })
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.owner_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not allow owner_id' do
      expect(result[:restrict_values]['owner_id']).not_to include(action_user.id)
    end

    it 'does not hide priority id' do
      expect(result[:visibility]['priority_id']).to eq('show')
    end
  end

  describe '.perform - Clean up params after restrict values removed selected value by default attributes' do
    let(:payload) do
      base_payload.merge('params' => {
                           'owner_id' => action_user.id,
                         })
    end

    before do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.owner_id': {
                 operator: 'is_set',
               },
             },
             perform:            {
               'ticket.priority_id': {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not allow owner_id' do
      expect(result[:restrict_values]['owner_id']).not_to include(action_user.id)
    end

    it 'does not hide priority id' do
      expect(result[:visibility]['priority_id']).to eq('show')
    end
  end

  describe '.perform - Default - auto selection based on only_shown_if_selectable' do
    it 'does auto select group' do
      expect(result[:select]['group_id']).not_to be_nil
    end

    it 'does auto hide group' do
      expect(result[:visibility]['group_id']).to eq('hide')
    end
  end

  describe '.perform - One field and two perform actions' do
    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.owner_id': {
                 operator:     %w[select set_optional],
                 select:       [action_user.id.to_s],
                 set_optional: 'true',
               },
             })
    end

    it 'does auto select owner' do
      expect(result[:select]['owner_id']).to eq(action_user.id.to_s)
    end

    it 'does set owner optional' do
      expect(result[:mandatory]['owner_id']).to be(false)
    end
  end

  describe '.perform - Hide mobile based on user login' do
    let(:base_payload) do
      {
        'event'      => 'core_workflow',
        'request_id' => 'default',
        'class_name' => 'User',
        'screen'     => 'create',
        'params'     => {
          'login' => 'nicole.special@zammad.org',
        },
      }
    end

    before do
      create(:core_workflow,
             object:             'User',
             condition_selected: { 'user.login'=>{ 'operator' => 'is', 'value' => 'nicole.special@zammad.org' } },
             perform:            { 'user.mobile'=>{ 'operator' => 'hide', 'hide' => 'true' } },)
    end

    it 'does hide mobile for user' do
      expect(result[:visibility]['mobile']).to eq('hide')
    end
  end

  describe '.perform - Readonly' do
    let!(:workflow1) do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.group_id': {
                 operator:     'set_readonly',
                 set_readonly: 'true'
               },
             })
    end

    it 'does match workflow' do
      expect(result[:matched_workflows]).to include(workflow1.id)
    end

    it 'does set group readonly' do
      expect(result[:readonly]['group_id']).to be(true)
    end

    context 'when readonly unset' do
      let!(:workflow2) do
        create(:core_workflow,
               object:  'Ticket',
               perform: {
                 'ticket.group_id': {
                   operator:       'unset_readonly',
                   unset_readonly: 'true'
                 },
               })
      end

      it 'does match workflows' do
        expect(result[:matched_workflows]).to include(workflow1.id, workflow2.id)
      end

      it 'does set group readonly' do
        expect(result[:readonly]['group_id']).to be(false)
      end
    end
  end
end

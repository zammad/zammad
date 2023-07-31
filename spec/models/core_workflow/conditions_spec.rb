# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe 'CoreWorkflow > Conditions', mariadb: true, type: :model do
  include_context 'with core workflow base'

  describe '.perform - Condition - today' do
    let(:ticket_created_at) { DateTime.new 2023, 7, 21, 10, 0 }
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'when match' do
      before do
        travel_to DateTime.new 2023, 7, 21, 7, 0
      end

      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'today',
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      before do
        travel_to DateTime.new 2023, 8, 21, 7, 0
      end

      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'today',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - after (absolute)' do
    let(:ticket_created_at) { DateTime.new 2023, 7, 21, 10, 0 }
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'after (absolute)',
                   value:    DateTime.new(2023, 7, 21, 9, 0).to_s
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'after (absolute)',
                   value:    DateTime.new(2023, 7, 21, 11, 0).to_s
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - after (relative)' do
    let(:ticket_created_at) { DateTime.new 2023, 7, 21, 10, 0 }
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    before do
      travel_to DateTime.new 2023, 7, 21, 7, 0
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'after (relative)',
                   range:    'hour',
                   value:    '1',
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'after (relative)',
                   range:    'hour',
                   value:    '4',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - before (absolute)' do
    let(:ticket_created_at) { DateTime.new 2023, 7, 21, 10, 0 }
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'before (absolute)',
                   value:    DateTime.new(2023, 7, 21, 11, 0).to_s
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'before (absolute)',
                   value:    DateTime.new(2023, 7, 21, 9, 0).to_s
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - before (relative)' do
    let(:ticket_created_at) { DateTime.new 2023, 7, 21, 10, 0 }
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    before do
      travel_to DateTime.new 2023, 7, 21, 12, 0
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'before (relative)',
                   range:    'hour',
                   value:    '1',
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'before (relative)',
                   range:    'hour',
                   value:    '4',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when empty' do
      let(:payload) do
        base_payload
      end

      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'before (relative)',
                   range:    'month',
                   value:    '1',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - from (relative)' do
    let(:ticket_created_at) { DateTime.new 2023, 7, 21, 10, 0 }
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    before do
      travel_to DateTime.new 2023, 7, 21, 12, 0
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'from (relative)',
                   range:    'hour',
                   value:    '4',
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'from (relative)',
                   range:    'hour',
                   value:    '1',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - till (relative)' do
    let(:ticket_created_at) { DateTime.new 2023, 7, 21, 10, 0 }
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    before do
      travel_to DateTime.new 2023, 7, 21, 8, 0
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'till (relative)',
                   range:    'hour',
                   value:    '4',
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'till (relative)',
                   range:    'hour',
                   value:    '1',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - within last (relative)' do
    let(:ticket_created_at) { DateTime.new 2023, 7, 21, 10, 0 }
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    before do
      travel_to DateTime.new 2023, 7, 21, 12, 0
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'within last (relative)',
                   range:    'hour',
                   value:    '4',
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'within last (relative)',
                   range:    'hour',
                   value:    '1',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - within next (relative)' do
    let(:ticket_created_at) { DateTime.new 2023, 7, 21, 10, 0 }
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    before do
      travel_to DateTime.new 2023, 7, 21, 8, 0
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'within next (relative)',
                   range:    'hour',
                   value:    '4',
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.created_at': {
                   operator: 'within next (relative)',
                   range:    'hour',
                   value:    '1',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Mention User IDs' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    before do
      ticket.mentions.create!(user: action_user, created_by_id: 1, updated_by_id: 1)
    end

    context 'when pre_condtion specific' do
      context 'when match' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.mention_user_ids': {
                     pre_condition: 'specific',
                     operator:      'is',
                     value:         [action_user.id.to_s],
                   },
                 })
        end

        it 'does match' do
          expect(result[:matched_workflows]).to include(workflow.id)
        end
      end

      context 'when mismatch' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.mention_user_ids': {
                     pre_condition: 'specific',
                     operator:      'is',
                     value:         ['999'],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end

    context 'when pre_condtion current_user.id' do
      context 'when match' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.mention_user_ids': {
                     pre_condition: 'current_user.id',
                     operator:      'is',
                     value:         [],
                   },
                 })
        end

        it 'does match' do
          expect(result[:matched_workflows]).to include(workflow.id)
        end
      end

      context 'when mismatch' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.mention_user_ids': {
                     pre_condition: 'current_user.id',
                     operator:      'is',
                     value:         [],
                   },
                 })
        end

        before do
          ticket.mentions.destroy_all
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end

    context 'when pre_condtion not_set' do
      context 'when match' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.mention_user_ids': {
                     pre_condition: 'not_set',
                     operator:      'is',
                     value:         [],
                   },
                 })
        end

        before do
          ticket.mentions.destroy_all
        end

        it 'does match' do
          expect(result[:matched_workflows]).to include(workflow.id)
        end
      end

      context 'when mismatch' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.mention_user_ids': {
                     pre_condition: 'not_set',
                     operator:      'is',
                     value:         [],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end
  end

  describe '.perform - Condition - Tags' do
    context 'when create' do
      context 'when match' do
        let(:payload) do
          base_payload.merge('params' => { 'tags' => 'special, special2' })
        end

        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.tags': {
                     operator: 'contains all',
                     value:    ['special'],
                   },
                 })
        end

        it 'does match' do
          expect(result[:matched_workflows]).to include(workflow.id)
        end
      end

      context 'when mismatch' do
        let(:payload) do
          base_payload.merge('params' => { 'tags' => 'special' }, 'screen' => 'create')
        end

        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.tags': {
                     operator: 'contains all',
                     value:    ['NOPE'],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end

    context 'when edit' do
      let(:payload) do
        base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
      end

      before do
        ticket.tag_add('special', 1)
      end

      context 'when match' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.tags': {
                     operator: 'contains all',
                     value:    ['special'],
                   },
                 })
        end

        it 'does match' do
          expect(result[:matched_workflows]).to include(workflow.id)
        end
      end

      context 'when mismatch' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.tags': {
                     operator: 'contains all',
                     value:    ['NOPE'],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end

    context 'when mobile create' do
      context 'when match' do
        let(:payload) do
          base_payload.merge('params' => { 'tags' => %w[special special2] })
        end

        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.tags': {
                     operator: 'contains all',
                     value:    ['special'],
                   },
                 })
        end

        it 'does match' do
          expect(result[:matched_workflows]).to include(workflow.id)
        end
      end

      context 'when mismatch' do
        let(:payload) do
          base_payload.merge('params' => { 'tags' => ['special'] }, 'screen' => 'create')
        end

        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.tags': {
                     operator: 'contains all',
                     value:    ['NOPE'],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end

    context 'when contains one' do
      context 'when match' do
        let(:payload) do
          base_payload.merge('params' => { 'tags' => 'special, special2' })
        end

        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.tags': {
                     operator: 'contains one',
                     value:    ['special'],
                   },
                 })
        end

        it 'does match' do
          expect(result[:matched_workflows]).to include(workflow.id)
        end
      end

      context 'when mismatch' do
        let(:payload) do
          base_payload.merge('params' => { 'tags' => 'special' }, 'screen' => 'create')
        end

        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   'ticket.tags': {
                     operator: 'contains one',
                     value:    ['NOPE'],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end
  end

  describe '.perform - Condition - Article' do
    let(:payload) do
      base_payload.merge('params' => { 'article' => {
                           body:            'hello',
                           type:            'note',
                           internal:        true,
                           form_id:         '210458899',
                           shared_draft_id: '',
                           subtype:         '',
                           in_reply_to:     '',
                           to:              '',
                           cc:              '',
                           subject:         '',
                           from:            'Test Admin Agent',
                           ticket_id:       5,
                           content_type:    'text/html',
                           sender_id:       1,
                           type_id:         10
                         } })
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'article.body': {
                   operator: 'regex match',
                   value:    'hello',
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'article.body': {
                   operator: 'regex match',
                   value:    'NOPE',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - owner_id not set' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.owner_id': {
                 operator: 'not_set',
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for owner id 1' do
      let(:payload) do
        base_payload.merge(
          'params' => { 'owner_id' => '1' },
        )
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.role_ids' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.role_ids': {
                 operator: 'is',
                 value:    [ Role.find_by(name: 'Agent').id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.group_ids_full' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.group_ids_full': {
                 operator: 'is',
                 value:    [ ticket.group.id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.group_ids_change' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.group_ids_change': {
                 operator: 'is',
                 value:    [ ticket.group.id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.group_ids_read' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.group_ids_read': {
                 operator: 'is',
                 value:    [ ticket.group.id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.group_ids_overview' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.group_ids_overview': {
                 operator: 'is',
                 value:    [ ticket.group.id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.group_ids_create' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.group_ids_create': {
                 operator: 'is',
                 value:    [ ticket.group.id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - session.permission_ids' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'session.permission_ids': {
                 operator: 'is',
                 value:    [ Permission.find_by(name: 'ticket.agent').id.to_s ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for customer' do
      let!(:action_user) { create(:customer) } # rubocop:disable RSpec/LetSetup

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Regex match' do
    let(:payload) do
      base_payload.merge(
        'params' => { 'title' => 'workflow ticket' },
      )
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.title': {
                 operator: 'regex match',
                 value:    [ '^workflow' ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for invalid regex' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'regex match',
                   value:    [ '^workfluw' ],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Regex mismatch' do
    let(:payload) do
      base_payload.merge(
        'params' => { 'title' => 'workflow ticket' },
      )
    end
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.title': {
                 operator: 'regex mismatch',
                 value:    [ '^workfluw' ],
               },
             })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end

    describe 'for invalid regex' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'regex mismatch',
                   value:    [ '^workflow' ],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Contains', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }

    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               "ticket.#{field_name}": {
                 operator: 'contains',
                 value:    %w[key_1 key_2],
               },
             })
    end

    before do
      create(:object_manager_attribute_multiselect, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
    end

    context 'when empty' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => [] },
        )
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when same value' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => %w[key_1 key_2] },
        )
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when 50% value' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => ['key_1'] },
        )
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when value differs' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => ['key_3'] },
        )
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Contains not', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }

    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               "ticket.#{field_name}": {
                 operator: 'contains not',
                 value:    %w[key_1 key_2],
               },
             })
    end

    before do
      create(:object_manager_attribute_multiselect, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
    end

    context 'when empty' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => [] },
        )
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when same value' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => %w[key_1 key_2] },
        )
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when 50% value' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => ['key_1'] },
        )
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when value differs' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => ['key_3'] },
        )
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Contains all', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }

    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               "ticket.#{field_name}": {
                 operator: 'contains all',
                 value:    %w[key_1 key_2],
               },
             })
    end

    before do
      create(:object_manager_attribute_multiselect, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
    end

    context 'when empty' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => [] },
        )
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when same value' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => %w[key_1 key_2] },
        )
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when 50% value' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => ['key_1'] },
        )
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when value differs' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => ['key_3'] },
        )
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Contains all not', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }

    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               "ticket.#{field_name}": {
                 operator: 'contains all not',
                 value:    %w[key_1 key_2],
               },
             })
    end

    before do
      create(:object_manager_attribute_multiselect, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
    end

    context 'when empty' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => [] },
        )
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when same value' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => %w[key_1 key_2] },
        )
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when 50% value' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => ['key_1'] },
        )
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when value differs' do
      let(:payload) do
        base_payload.merge(
          'params' => { field_name => ['key_3'] },
        )
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - group active is true' do
    let(:payload) do
      base_payload.merge('params' => {
                           'group_id' => Group.first.id,
                         })
    end

    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'group.active'=>{ 'operator' => 'is', 'value' => true } })
    end

    it 'does match' do
      expect(result[:matched_workflows]).to include(workflow.id)
    end
  end

  describe '.perform - Condition - group.assignment_timeout (Integer) matches' do
    let(:group) { create(:group, assignment_timeout: 10) }
    let(:payload) do
      base_payload.merge('params' => {
                           'group_id' => group.id,
                         })
    end

    before do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'group.assignment_timeout'=>{ 'operator' => 'is', 'value' => 10 } },
             perform:            { 'ticket.priority_id'=>{ 'operator' => 'hide', 'hide' => 'true' } },)
    end

    it 'does match' do
      expect(result[:visibility]['priority_id']).to eq('hide')
    end
  end

  describe '.perform - Condition - starts with' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'when match' do
      before do
        travel_to DateTime.new 2023, 7, 21, 7, 0
      end

      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'starts with',
                   value:    ticket_title[0..5]
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      before do
        travel_to DateTime.new 2023, 8, 21, 7, 0
      end

      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'starts with',
                   value:    'xxx',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when empty' do
      before do
        travel_to DateTime.new 2023, 8, 21, 7, 0
        ticket.customer.update(note: nil)
      end

      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'customer.note': {
                   operator: 'starts with',
                   value:    'xxx',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - ends with' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'when match' do
      before do
        travel_to DateTime.new 2023, 7, 21, 7, 0
      end

      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'ends with',
                   value:    ticket_title[-5..]
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when mismatch' do
      before do
        travel_to DateTime.new 2023, 8, 21, 7, 0
      end

      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'ends with',
                   value:    'xxx',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when empty' do
      before do
        travel_to DateTime.new 2023, 8, 21, 7, 0
        ticket.customer.update(note: nil)
      end

      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'customer.note': {
                   operator: 'ends with',
                   value:    'xxx',
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end
end

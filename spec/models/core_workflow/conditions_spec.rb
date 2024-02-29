# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
                           form_id:         SecureRandom.uuid,
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
                   operator: 'matches regex',
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
                   operator: 'matches regex',
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

  describe '.perform - Condition - Matches regex' do
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
                 operator: 'matches regex',
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
                   operator: 'matches regex',
                   value:    [ '^workfluw' ],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - Does not match regex' do
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
                 operator: 'does not match regex',
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
                   operator: 'does not match regex',
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

  describe '.perform - Condition - starts with one of' do
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
                   operator: 'starts with one of',
                   value:    [ticket_title[0..5]]
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
                   operator: 'starts with one of',
                   value:    ['xxx'],
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
                   operator: 'starts with one of',
                   value:    ['xxx'],
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

  describe '.perform - Condition - ends with one of' do
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
                   operator: 'ends with one of',
                   value:    [ticket_title[-5..]]
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
                   operator: 'ends with one of',
                   value:    ['xxx'],
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
                   operator: 'ends with one of',
                   value:    ['xxx'],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - is any of' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'is any of',
                   value:    ['a', 'b', ticket_title],
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
                 'ticket.title': {
                   operator: 'is any of',
                   value:    ['xxx'],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when empty' do
      before do
        ticket.update!(title: '')
      end

      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'is any of',
                   value:    ['xxx'],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - is none of' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'is none of',
                   value:    %w[a b c],
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
                 'ticket.title': {
                   operator: 'is none of',
                   value:    [ticket.title],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'when empty' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.title': {
                   operator: 'is none of',
                   value:    [ticket.title],
                 },
               })
      end

      it 'does match' do
        ticket.update!(title: '')
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe '.perform - Condition - is' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.group_id': {
                   operator: 'is',
                   value:    [ticket.group.id.to_s],
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
                 'ticket.group_id': {
                   operator: 'is',
                   value:    [Group.first.id],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'with new external data source field', db_adapter: :postgresql, db_strategy: :reset do
      let!(:external_data_source_attribute) do
        attribute = create(:object_manager_attribute_autocompletion_ajax_external_data_source,
                           name: 'external_data_source_attribute')
        ObjectManager::Attribute.migration_execute

        attribute
      end

      let(:condition_field_name) { "ticket.#{external_data_source_attribute.name}" }

      let(:additional_ticket_attributes) do
        {
          external_data_source_attribute.name => {
            value: 123,
            label: 'Example',
          }
        }
      end

      context 'when match' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   condition_field_name => {
                     operator: 'is',
                     value:    [
                       {
                         value: 123,
                         label: 'Example',
                       }
                     ],
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
                   condition_field_name => {
                     operator: 'is',
                     value:    [
                       {
                         value: 986,
                         label: 'Example',
                       }
                     ],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end
  end

  describe '.perform - Condition - is not' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.group_id': {
                   operator: 'is not',
                   value:    [Group.first.id.to_s],
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
                 'ticket.group_id': {
                   operator: 'is not',
                   value:    [ticket.group.id.to_s],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'with new external data source field', db_adapter: :postgresql, db_strategy: :reset do
      let!(:external_data_source_attribute) do
        attribute = create(:object_manager_attribute_autocompletion_ajax_external_data_source,
                           name: 'external_data_source_attribute')
        ObjectManager::Attribute.migration_execute

        attribute
      end

      let(:condition_field_name) { "ticket.#{external_data_source_attribute.name}" }

      let(:additional_ticket_attributes) do
        {
          external_data_source_attribute.name => {
            value: 123,
            label: 'Example',
          }
        }
      end

      context 'when match' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   condition_field_name => {
                     operator: 'is not',
                     value:    [
                       {
                         value: 986,
                         label: 'Example',
                       }
                     ],
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
                   condition_field_name => {
                     operator: 'is not',
                     value:    [
                       {
                         value: 123,
                         label: 'Example',
                       }
                     ],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end
  end

  describe '.perform - Condition - is set' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.group_id': {
                   operator: 'is set',
                   value:    [],
                 },
               })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'with new external data source field', db_adapter: :postgresql, db_strategy: :reset do
      let!(:external_data_source_attribute) do
        attribute = create(:object_manager_attribute_autocompletion_ajax_external_data_source,
                           name: 'external_data_source_attribute')
        ObjectManager::Attribute.migration_execute

        attribute
      end

      let(:condition_field_name) { "ticket.#{external_data_source_attribute.name}" }

      context 'when match' do
        let(:additional_ticket_attributes) do
          {
            external_data_source_attribute.name => {
              value: 123,
              label: 'Example',
            }
          }
        end

        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   condition_field_name => {
                     operator: 'is set',
                     value:    [],
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
                   condition_field_name => {
                     operator: 'is set',
                     value:    [],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end
  end

  describe '.perform - Condition - not set' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    context 'with new external data source field', db_adapter: :postgresql, db_strategy: :reset do
      let!(:external_data_source_attribute) do
        attribute = create(:object_manager_attribute_autocompletion_ajax_external_data_source,
                           name: 'external_data_source_attribute')
        ObjectManager::Attribute.migration_execute

        attribute
      end

      let(:condition_field_name) { "ticket.#{external_data_source_attribute.name}" }

      context 'when match' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   condition_field_name => {
                     operator: 'not set',
                     value:    [],
                   },
                 })
        end

        it 'does match' do
          expect(result[:matched_workflows]).to include(workflow.id)
        end
      end

      context 'when mismatch' do
        let(:additional_ticket_attributes) do
          {
            external_data_source_attribute.name => {
              value: 123,
              label: 'Example',
            }
          }
        end

        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   condition_field_name => {
                     operator: 'not set',
                     value:    [],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end
  end

  describe '.perform - Condition - changed to' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit', 'last_changed_attribute' => 'group_id')
    end

    context 'when match' do
      let!(:workflow) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.group_id': {
                   operator: 'changed to',
                   value:    [ticket.group.id.to_s],
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
                 'ticket.group_id': {
                   operator: 'changed to',
                   value:    [Group.first.id],
                 },
               })
      end

      it 'does not match' do
        expect(result[:matched_workflows]).not_to include(workflow.id)
      end
    end

    context 'with new external data source field', db_adapter: :postgresql, db_strategy: :reset do
      let(:payload) do
        base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit', 'last_changed_attribute' => external_data_source_attribute.name)
      end

      let!(:external_data_source_attribute) do
        attribute = create(:object_manager_attribute_autocompletion_ajax_external_data_source,
                           name: 'external_data_source_attribute')
        ObjectManager::Attribute.migration_execute

        attribute
      end

      let(:condition_field_name) { "ticket.#{external_data_source_attribute.name}" }

      let(:additional_ticket_attributes) do
        {
          external_data_source_attribute.name => {
            value: 123,
            label: 'Example',
          }
        }
      end

      context 'when match' do
        let!(:workflow) do
          create(:core_workflow,
                 object:             'Ticket',
                 condition_selected: {
                   condition_field_name => {
                     operator: 'changed to',
                     value:    [
                       {
                         value: 123,
                         label: 'Example',
                       }
                     ],
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
                   condition_field_name => {
                     operator: 'changed to',
                     value:    [
                       {
                         value: 986,
                         label: 'Example',
                       }
                     ],
                   },
                 })
        end

        it 'does not match' do
          expect(result[:matched_workflows]).not_to include(workflow.id)
        end
      end
    end
  end

  describe 'New ticket organization condition in core workflow not working for is specific usage #4750' do
    let(:ticket_customer) { create(:customer, :with_org) }

    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.organization_id': {
                 operator: 'is',
                 value:    [ticket.customer.organization_id.to_s],
               },
             })
    end

    context 'when agent' do
      let(:payload) do
        base_payload.merge('params' => { 'customer_id' => ticket.customer_id })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end

    context 'when customer' do
      let!(:action_user) { ticket.customer } # rubocop:disable RSpec/LetSetup

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow.id)
      end
    end
  end

  describe 'Core Workflow: Readded options are not usable in conditions #4763' do
    before do
      workflow_1 && workflow_2
    end

    context 'when single value' do
      let(:workflow_1) do
        create(:core_workflow,
               object:  'Ticket',
               perform: {
                 'ticket.priority_id': {
                   operator:      'remove_option',
                   remove_option: Ticket::Priority.pluck(:id).map(&:to_s),
                 },
               })
      end
      let(:workflow_2) do
        create(:core_workflow,
               object:  'Ticket',
               perform: {
                 'ticket.priority_id': {
                   operator:   'add_option',
                   add_option: Ticket::Priority.pluck(:id).map(&:to_s),
                 },
               })
      end
      let!(:workflow_3) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 'ticket.priority_id': {
                   operator: 'is',
                   value:    Ticket::Priority.where(name: '3 high').pluck(:id).map(&:to_s),
                 },
               })
      end
      let(:payload) do
        base_payload.merge('params' => { 'priority_id' => Ticket::Priority.find_by(name: '3 high').id.to_s })
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow_3.id)
      end
    end

    context 'when multiple value', db_strategy: :reset do
      let(:workflow_1) do
        create(:core_workflow,
               object:  'Ticket',
               perform: {
                 "ticket.#{field_name}": {
                   operator:      'remove_option',
                   remove_option: ['key_1'],
                 },
               })
      end
      let(:workflow_2) do
        create(:core_workflow,
               object:  'Ticket',
               perform: {
                 "ticket.#{field_name}": {
                   operator:   'add_option',
                   add_option: ['key_1'],
                 },
               })
      end
      let!(:workflow_3) do
        create(:core_workflow,
               object:             'Ticket',
               condition_selected: {
                 "ticket.#{field_name}": {
                   operator: 'is',
                   value:    ['key_1'],
                 },
               })
      end
      let(:payload) do
        base_payload.merge('params' => { field_name => ['key_1'] })
      end
      let(:field_name) { SecureRandom.uuid }

      before do
        create(:object_manager_attribute_multiselect, name: field_name, display: field_name)
        ObjectManager::Attribute.migration_execute
      end

      it 'does match' do
        expect(result[:matched_workflows]).to include(workflow_3.id)
      end
    end
  end
end

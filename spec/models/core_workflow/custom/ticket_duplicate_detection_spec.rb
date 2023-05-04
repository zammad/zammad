# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CoreWorkflow::Custom::TicketDuplicateDetection, type: :model do
  let(:ticket_group)                { create(:group) }
  let(:ticket_group_without_access) { create(:group) }
  let(:agent1)                      { create(:agent, groups: [ticket_group, ticket_group_without_access], firstname: 'Tickets', lastname: 'Agent') }
  let(:agent2)                      { create(:agent, groups: [], firstname: 'Tickets', lastname: 'Agent') }
  let(:ticket1)                     { create(:ticket, title: '123', group: ticket_group) }
  let(:ticket2)                     { create(:ticket, title: 'ABC', group: ticket_group) }
  let(:ticket3)                     { create(:ticket, title: '123', group: ticket_group_without_access) }
  let(:result)                      { CoreWorkflow.perform(payload: payload, user: action_user) }

  let(:payload) do
    {
      'event'                  => 'core_workflow',
      'request_id'             => 'default',
      'class_name'             => 'Ticket',
      'screen'                 => 'create_middle',
      'params'                 => { 'title' => '123' },
      'last_changed_attribute' => 'title',
    }
  end

  before do
    ticket1 && ticket2 && ticket3

    Setting.set('ticket_duplicate_detection', true)
    Setting.set('ticket_duplicate_detection_attributes', ['title'])
  end

  context 'when matching on title' do
    context 'when permission level user' do
      context 'with agent 1 which has access' do
        let(:action_user) { agent1 }

        it 'does return count of 2 and 2 accessible tickets for agent1' do
          expect(result[:fill_in]['ticket_duplicate_detection'])
            .to be_a(Hash)
            .and include(items: [[ticket1.id, ticket1.number, ticket1.title], [ticket3.id, ticket3.number, ticket3.title]])
            .and include(count: 2)
        end
      end

      context 'with agent 2 which has no access' do
        let(:action_user) { agent2 }

        it 'does return count of 0 and 0 accessible tickets for agent2' do
          expect(result[:fill_in]['ticket_duplicate_detection'])
            .to be_a(Hash)
            .and include(items: [])
            .and include(count: 0)
        end
      end
    end

    context 'when permission level system' do
      before do
        Setting.set('ticket_duplicate_detection_permission_level', 'system')
      end

      context 'with agent 1 which has access' do
        let(:action_user) { agent1 }

        it 'does return count of 2 and 2 accessible tickets for agent1' do
          expect(result[:fill_in]['ticket_duplicate_detection'])
            .to be_a(Hash)
            .and include(items: [[ticket1.id, ticket1.number, ticket1.title], [ticket3.id, ticket3.number, ticket3.title]])
            .and include(count: 2)
        end
      end

      context 'with agent 2 which has no access' do
        let(:action_user) { agent2 }

        it 'does return count of 2 and 0 accessible tickets for agent2' do
          expect(result[:fill_in]['ticket_duplicate_detection'])
            .to be_a(Hash)
            .and include(items: [])
            .and include(count: 2)
        end
      end
    end
  end

  context 'when show tickets disabled' do
    before do
      Setting.set('ticket_duplicate_detection_show_tickets', false)
    end

    context 'when permission level user' do
      context 'with agent 1 which has access' do
        let(:action_user) { agent1 }

        it 'does return count of 2 and 0 accessible tickets for agent1' do
          expect(result[:fill_in]['ticket_duplicate_detection'])
            .to be_a(Hash)
            .and include(items: [])
            .and include(count: 2)
        end
      end

      context 'with agent 2 which has no access' do
        let(:action_user) { agent2 }

        it 'does return count of 0 and 0 accessible tickets for agent2' do
          expect(result[:fill_in]['ticket_duplicate_detection'])
            .to be_a(Hash)
            .and include(items: [])
            .and include(count: 0)
        end
      end
    end

    context 'when permission level system' do
      before do
        Setting.set('ticket_duplicate_detection_permission_level', 'system')
      end

      context 'with agent 1 which has access' do
        let(:action_user) { agent1 }

        it 'does return count of 2 and 0 accessible tickets for agent1' do
          expect(result[:fill_in]['ticket_duplicate_detection'])
            .to be_a(Hash)
            .and include(items: [])
            .and include(count: 2)
        end
      end

      context 'with agent 2 which has no access' do
        let(:action_user) { agent2 }

        it 'does return count of 2 and 0 accessible tickets for agent2' do
          expect(result[:fill_in]['ticket_duplicate_detection'])
            .to be_a(Hash)
            .and include(items: [])
            .and include(count: 2)
        end
      end
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

  context 'when no attributes' do
    let(:action_user) { agent1 }
    let(:payload) do
      {
        'event'      => 'core_workflow',
        'request_id' => 'default',
        'class_name' => 'Ticket',
        'screen'     => 'create_middle',
        'params'     => { 'title' => '123' },
      }
    end

    before do
      Setting.set('ticket_duplicate_detection_attributes', [])
    end

    it 'does not return anything' do
      expect(result[:fill_in]['ticket_duplicate_detection']).to be_nil
    end
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

      context 'when param value is empty', db_strategy: :reset do
        let(:action_user) { agent1 }
        let(:field_name)  { SecureRandom.uuid }

        let(:payload) do
          {
            'event'                  => 'core_workflow',
            'request_id'             => 'default',
            'class_name'             => 'Ticket',
            'screen'                 => 'create_middle',
            'params'                 => { field_name => '' },
            'last_changed_attribute' => field_name,
          }
        end

        let(:screens) do
          {
            create_middle: {
              'ticket.agent' => {
                shown: true,
              },
            },
          }
        end

        before do
          Setting.set('ticket_duplicate_detection_attributes', [field_name])
          create(:object_manager_attribute_text, object_name: 'Ticket', name: field_name, display: field_name, screens: screens)
          ObjectManager::Attribute.migration_execute
          create(:ticket, field_name => '')
        end

        it 'does return count of 0 and will clear the current state' do
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

  context 'when customer and duplication attributes contain title and customer #4643' do
    let(:customer) { create(:customer) }
    let(:ticket1) { create(:ticket, title: '123', group: ticket_group, customer: customer) }

    before do
      Setting.set('ticket_duplicate_detection', true)
      Setting.set('ticket_duplicate_detection_attributes', %w[title customer_id])
      Setting.set('ticket_duplicate_detection_role_ids', [Role.find_by(name: 'Agent').id, Role.find_by(name: 'Customer').id])
    end

    context 'when agent 1' do
      let(:action_user) { agent1 }

      let(:payload) do
        {
          'event'                  => 'core_workflow',
          'request_id'             => 'default',
          'class_name'             => 'Ticket',
          'screen'                 => 'create_middle',
          'params'                 => { 'title' => '123', 'customer_id' => customer.id.to_s },
          'last_changed_attribute' => 'title',
        }
      end

      it 'does return count of 1' do
        expect(result[:fill_in]['ticket_duplicate_detection'])
          .to be_a(Hash)
          .and include(items: [[ticket1.id, ticket1.number, ticket1.title]])
          .and include(count: 1)
      end
    end

    context 'when customer' do
      let(:action_user) { customer }

      let(:payload) do
        {
          'event'                  => 'core_workflow',
          'request_id'             => 'default',
          'class_name'             => 'Ticket',
          'screen'                 => 'create_middle',
          'params'                 => { 'title' => '123' }, # no customer_id because customer don't have this field
          'last_changed_attribute' => 'title',
        }
      end

      it 'does return count of 1' do
        expect(result[:fill_in]['ticket_duplicate_detection'])
          .to be_a(Hash)
          .and include(items: [[ticket1.id, ticket1.number, ticket1.title]])
          .and include(count: 1)
      end
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'ChecksHumanChanges' do
  describe 'checks human changes' do
    subject { described_class.new(item).human_changes(item_changes, ticket, agent) }

    let(:agent)  { create(:agent) }
    let(:ticket) { create(:ticket) }
    let(:item) do
      {
        object:           'Ticket',
        type:             'update',
        object_id:        ticket.id,
        interface_handle: 'application_server',
        changes:          item_changes,
        created_at:       Time.zone.now,
        user_id:          1,
      }
    end
    let(:item_changes) { {} }

    context 'without human changes' do
      it 'check for changes' do
        expect(subject).to eq({})
      end
    end

    context 'with human changes' do
      let(:item_changes) do
        {
          'priority_id'  => [Ticket::Priority.find_by(name: '2 normal').id, Ticket::Priority.find_by(name: '3 high').id],
          'pending_time' => [nil, Time.zone.parse('2015-01-11 23:33:47 UTC')],
        }
      end

      before do
        ticket.update!(priority_id: Ticket::Priority.find_by(name: '3 high').id)
      end

      it 'check for changes' do
        expect(subject).to eq({
                                'Priority'     => ['2 normal', '3 high'],
                                'Pending till' => [nil, Time.zone.parse('2015-01-11 23:33:47 UTC')],
                              })
      end

      context 'without a user' do
        let(:agent) { nil }

        it 'check for changes' do
          expect(subject).to eq({
                                  'Priority'     => ['2 normal', '3 high'],
                                  'Pending till' => [nil, Time.zone.parse('2015-01-11 23:33:47 UTC')],
                                })
        end
      end
    end
  end
end

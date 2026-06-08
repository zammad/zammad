# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::User::Current::Ticket::BulkUpdateStatusUpdates, type: :graphql do
  let(:subscription) do
    <<~QUERY
      subscription userCurrentTicketBulkUpdateStatusUpdates {
        userCurrentTicketBulkUpdateStatusUpdates {
          bulkUpdateStatus {
            status
            total
            processedCount
            failedCount
          }
        }
      }
    QUERY
  end

  let(:mock_channel) { build_mock_channel }
  let(:target)       { create(:agent) }

  context 'with authenticated user', authenticated_as: :target do
    describe '#subscribe' do
      context 'when no bulk update is running' do
        it 'subscribes' do
          gql.execute(subscription, context: { channel: mock_channel })
          expect(gql.result.data).to include('bulkUpdateStatus' => include('status' => 'none'))
        end
      end

      context 'when a bulk update is running' do
        before do
          TicketBulkUpdateJob.perform_later(user: target, perform: {}, ticket_ids: [1, 2, 3], total: 100, processed_count: 50)
        end

        it 'subscribes' do
          gql.execute(subscription, context: { channel: mock_channel })
          expect(gql.result.data)
            .to include(
              'bulkUpdateStatus' => include(
                'status' => 'running', 'total' => 100, 'processedCount' => 50
              )
            )
        end
      end
    end

    describe '#update' do
      before do
        gql.execute(subscription, context: { channel: mock_channel })

        described_class.trigger(
          {
            status:       'failed',
            failed_count: 123,
            total:        256
          },
          scope: user.id
        )
      end

      context 'with updates for the current user' do
        let(:user) { target }

        it 'forwards given data' do
          result = mock_channel.mock_broadcasted_messages.first[:result]

          expect(result['data']['userCurrentTicketBulkUpdateStatusUpdates'])
            .to include('bulkUpdateStatus' => include(
              'status' => 'failed', 'total' => 256, 'failedCount' => 123
            ))
        end
      end

      context 'with updates for another user' do
        let(:user) { create(:agent) }

        it 'does not receive updates for other users' do
          expect(mock_channel.mock_broadcasted_messages).to be_empty
        end
      end
    end
  end
end

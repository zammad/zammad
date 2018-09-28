require 'rails_helper'

RSpec.describe 'Time Accounting API endpoints', type: :request do
  let(:admin)    { create(:admin_user) }
  let(:customer) { create(:customer_user) }
  let(:year)     { Time.current.year }
  let(:month)    { Time.current.month }

  describe '/api/v1/time_accounting/log/by_ticket' do
    context 'when requesting a JSON response' do
      # see https://github.com/zammad/zammad/pull/2243
      context 'and logs exist for work performed by an agent who is also the customer of the ticket (#2243)' do
        let(:ticket) { create(:ticket, customer: admin) }
        let!(:time_log) { create(:ticket_time_accounting, ticket: ticket, created_by_id: admin.id) }

        it 'responds with a non-nil value for each :agent key' do
          authenticated_as(admin)
          get "/api/v1/time_accounting/log/by_ticket/#{year}/#{month}", as: :json

          expect(json_response.first).not_to include('agent' => nil)
        end
      end
    end
  end
end

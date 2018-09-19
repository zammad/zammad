require 'rails_helper'

RSpec.describe 'Time Accounting', type: :request do

  let(:admin_user) do
    create(:admin_user)
  end
  let(:customer_user) do
    create(:customer_user)
  end
  let(:year) do
    DateTime.now.utc.year
  end
  let(:month) do
    DateTime.now.utc.month
  end

  describe 'request handling' do

    it 'does time account report' do
      group   = create(:group)
      ticket  = create(:ticket, state: Ticket::State.lookup(name: 'open'), customer: customer_user )
      article = create(:ticket_article, ticket_id: ticket.id, type: Ticket::Article::Type.lookup(name: 'note') )

      create(:ticket_time_accounting, ticket_id: ticket.id, ticket_article_id: article.id)

      authenticated_as(admin_user)
      get "/api/v1/time_accounting/log/by_ticket/#{year}/#{month}?download=true", params: {}

      expect(response).to have_http_status(200)
      expect(response['Content-Disposition']).to be_truthy
      expect(response['Content-Disposition']).to eq("attachment; filename=\"by_ticket-#{year}-#{month}.xls\"")
      expect(response['Content-Type']).to eq('application/vnd.ms-excel')
    end
  end
end

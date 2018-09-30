require 'rails_helper'

RSpec.describe 'Report', type: :request, searchindex: true do

  let!(:admin_user) do
    create(:admin_user)
  end
  let!(:agent_user) do
    create(:agent_user)
  end
  let!(:customer_user) do
    create(:customer_user)
  end
  let!(:year) do
    DateTime.now.utc.year
  end
  let!(:month) do
    DateTime.now.utc.month
  end
  let!(:week) do
    DateTime.now.utc.strftime('%U').to_i
  end
  let!(:day) do
    DateTime.now.utc.day
  end
  let!(:ticket) do
    create(:ticket, title: 'ticket for report', customer: customer_user)
  end
  let!(:article) do
    create(:ticket_article, ticket_id: ticket.id, type: Ticket::Article::Type.lookup(name: 'note') )
  end

  before(:each) do
    configure_elasticsearch do

      travel 1.minute

      rebuild_searchindex

      # execute background jobs
      Scheduler.worker(true)

      sleep 6
    end
  end

  describe 'request handling' do

    it 'does report example - admin access' do
      authenticated_as(admin_user)
      get "/api/v1/reports/sets?sheet=true;metric=count;year=#{year};month=#{month};week=#{week};day=#{day};timeRange=year;profile_id=1;downloadBackendSelected=count::created", params: {}, as: :json

      expect(response).to have_http_status(200)
      assert(@response['Content-Disposition'])
      expect(@response['Content-Disposition']).to eq('attachment; filename="tickets--all--Created.xls"')
      expect(@response['Content-Type']).to eq('application/vnd.ms-excel')
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket overviews', :aggregate_failures, authenticated_as: :agent, type: :request do
  let(:group)    { create(:group) }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:overview) { Overview.find_by(link: 'all_unassigned') }
  let!(:tickets) { create_list(:ticket, 2, group:) }

  describe 'GET /api/v1/ticket_overviews' do
    it 'returns every overview of the user with its ticket count' do
      get '/api/v1/ticket_overviews', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck('link')).to eq(Ticket::Overviews.all(current_user: agent).map(&:link))
      expect(json_response.find { |entry| entry['link'] == 'all_unassigned' }).to eq(
        'id'    => overview.id,
        'name'  => overview.name,
        'prio'  => overview.prio,
        'link'  => 'all_unassigned',
        'count' => 2,
      )
    end
  end

  describe 'GET /api/v1/ticket_overviews?view=' do
    def view_request_query_count
      queries = 0

      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        next if payload[:cached] || payload[:name] == 'SCHEMA'

        queries += 1
      end

      get '/api/v1/ticket_overviews', params: { view: 'all_unassigned' }, as: :json

      queries
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it 'returns the requested overview with its tickets and their assets' do
      expected_index = Ticket::Overviews.index(agent).find { |entry| entry[:overview][:view] == 'all_unassigned' }

      get '/api/v1/ticket_overviews', params: { view: 'all_unassigned' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response['index']).to eq(expected_index.as_json)
      expect(json_response['index']['tickets'].pluck('id')).to match_array(tickets.map(&:id))
      expect(json_response['assets']).to include_assets_of(overview, *tickets)
    end

    {
      'an unknown overview'                 => 'unknown_overview',
      'an overview the user may not access' => 'my_tickets',
      'a list of overviews'                 => ['all_unassigned'],
    }.each do |description, view|
      it "returns an empty index for #{description}" do
        get '/api/v1/ticket_overviews', params: { view: }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq('assets' => {}, 'index' => {})
      end
    end

    it 'does not compute the other overviews of the user' do
      # The first request after a change fills caches, so only warm requests are compared.
      get '/api/v1/ticket_overviews', params: { view: 'all_unassigned' }, as: :json
      baseline = view_request_query_count

      # Distinct conditions, because the query cache would answer the queries of identical ones.
      Ticket::Priority.find_each do |priority|
        create(:overview, condition: { 'ticket.priority_id' => { operator: 'is', value: [priority.id] } })
      end
      get '/api/v1/ticket_overviews', params: { view: 'all_unassigned' }, as: :json

      expect(view_request_query_count).to eq(baseline)
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Report', type: :request do

  let!(:admin) do
    create(:admin)
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
  let!(:today) do
    Time.zone.parse('2019-03-15T08:00:00Z')
  end
  let!(:backends) do
    {
      'count::created':             true,
      'count::closed':              true,
      'count::backlog':             true,
      'create_channels::phone_in':  true,
      'create_channels::phone_out': true,
      'create_channels::email_in':  true,
      'create_channels::email_out': true,
      'create_channels::web_in':    true,
      'communication::phone_in':    true,
      'communication::phone_out':   true,
      'communication::email_in':    true,
      'communication::email_out':   true,
      'communication::web_in':      true,
    }
  end

  describe 'request handling', searchindex: true do
    before do
      travel_to today.midday
      Ticket.destroy_all
      create(:ticket, title: 'ticket for report #1', created_at: today.midday)
      create(:ticket, title: 'ticket for report #2', created_at: today.midday + 2.hours)
      create(:ticket, title: 'ticket for report #3', created_at: today.midday + 2.hours)
      create(:ticket, title: 'ticket for report #4', created_at: today.midday + 10.hours, state: Ticket::State.lookup(name: 'closed'))
      create(:ticket, title: 'ticket for report #5', created_at: today.midday + 11.hours)
      create(:ticket, title: 'ticket for report #6', created_at: today.midday - 11.hours)
      create(:ticket, title: 'ticket for report #7', created_at: Time.zone.parse('2019-02-28T23:30:00Z'))
      create(:ticket, title: 'ticket for report #8', created_at: Time.zone.parse('2019-03-01T00:30:00Z'))
      create(:ticket, title: 'ticket for report #9', created_at: Time.zone.parse('2019-03-31T23:30:00Z'))
      create(:ticket, title: 'ticket for report #10', created_at: Time.zone.parse('2019-04-01T00:30:00Z'))

      searchindex_model_reload([Ticket, User])
    end

    describe '/api/v1/reports/generate' do

      it 'does report example - admin access' do
        authenticated_as(admin)
        get "/api/v1/reports/sets?sheet=true&metric=count&year=#{year}&month=#{month}&week=#{week}&day=#{day}&timeRange=year&profile_id=1&downloadBackendSelected=count::created", params: {}, as: :json

        expect(response).to have_http_status(:ok)
        assert(response['Content-Disposition'])
        expect(response['Content-Disposition']).to eq('attachment; filename="tickets--all--Created.xlsx"; filename*=UTF-8\'\'tickets--all--Created.xlsx')
        expect(response['Content-Type']).to eq(ExcelSheet::CONTENT_TYPE)
        expect(response.body).to start_with('PK')
        expect(response['Content-Length']).to eq(response.body.bytesize.to_s)
      end

      it 'does report example - deliver result in the default timezone' do
        Setting.set('timezone_default', 'Europe/Berlin')
        authenticated_as(admin)

        params = {
          metric:    'count',
          year:      today.year,
          month:     today.month,
          day:       today.day,
          timeRange: 'day',
          profiles:  {
            1 => true
          },
          backends:  backends
        }
        post '/api/v1/reports/generate', params: params, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['data']['count::created']).to eq([0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1])
        expect(json_response['data']['count::closed']).to eq([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        expect(json_response['data']['count::backlog']).to eq([0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1])
      end

      it 'does report example - cover every day of the requested month' do
        Setting.set('timezone_default', 'UTC')
        authenticated_as(admin)

        params = {
          metric:    'count',
          year:      today.year,
          month:     today.month,
          timeRange: 'month',
          profiles:  {
            1 => true
          },
          backends:  backends
        }
        post '/api/v1/reports/generate', params: params, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['data']['count::created']).to eq([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])
      end
    end

    describe 'Reporting Profile - query does not support [owner_id] #5462' do
      let(:user_report_profile)         { create(:report_profile, condition: { 'ticket.owner_id'=>{ 'operator' => 'is', 'pre_condition' => 'current_user.id', 'value' => [], 'value_completion' => '' } }) }
      let(:user_report_profile_unset)   { create(:report_profile, condition: { 'ticket.owner_id'=>{ 'operator' => 'is', 'pre_condition' => 'not_set', 'value' => [], 'value_completion' => '' } }) }
      let(:organization_report_profile) { create(:report_profile, condition: { 'ticket.organization_id'=>{ 'operator' => 'is', 'pre_condition' => 'current_user.organization_id', 'value' => [], 'value_completion' => '' } }) }

      let(:organization) { create(:organization) }
      let!(:owned_ticket)        { create(:ticket, group: Group.first, owner: admin, created_at: today) }
      let!(:organization_ticket) { create(:ticket, customer: create(:customer, organization:), created_at: today) }

      before do
        admin.update!(organization:, group_names_access_map: { Group.first.name => 'full' })
        searchindex_model_reload([Ticket])
        authenticated_as(admin)
      end

      def report_ticket_ids(profile)
        get '/api/v1/reports/sets', params: {
          'metric'                  => 'count',
          'year'                    => today.year,
          'month'                   => today.month,
          'day'                     => today.day,
          'timeRange'               => 'year',
          'profiles'                => {
            profile.id.to_s => true
          },
          'downloadBackendSelected' => 'count::created'
        }, as: :json

        expect(response).to have_http_status(:ok)
        json_response['ticket_ids'].map(&:to_i)
      end

      it 'does generate reports with current user condition' do
        expect(report_ticket_ids(user_report_profile)).to eq([owned_ticket.id])
      end

      it 'does generate reports with current user unset condition' do
        expect(report_ticket_ids(user_report_profile_unset))
          .to include(organization_ticket.id)
          .and not_include(owned_ticket.id)
      end

      it 'does generate reports with current organization condition' do
        expect(report_ticket_ids(organization_report_profile)).to eq([organization_ticket.id])
      end
    end
  end

  describe 'GET /api/v1/reports/config' do
    let(:report_permission_role) { create(:role).tap { |r| r.permission_grant('report') } }
    let(:profile_role)           { create(:role, active: true) }

    let!(:global_profile)     { create(:report_profile) }
    let!(:restricted_profile) { create(:report_profile, roles: [profile_role]) }

    before do
      Setting.set('es_url', 'http://localhost:9200')
    end

    it 'returns only visible profiles for user without matching roles' do
      user = create(:agent, roles: [report_permission_role])
      authenticated_as(user)

      get '/api/v1/reports/config', as: :json

      expect(response).to have_http_status(:ok)
      profile_ids = json_response['profiles'].pluck('id')
      expect(profile_ids).to include(global_profile.id)
      expect(profile_ids).not_to include(restricted_profile.id)
    end

    it 'returns restricted profiles when user has matching role' do
      user = create(:agent, roles: [report_permission_role, profile_role])
      authenticated_as(user)

      get '/api/v1/reports/config', as: :json

      expect(response).to have_http_status(:ok)
      profile_ids = json_response['profiles'].pluck('id')
      expect(profile_ids).to include(global_profile.id, restricted_profile.id)
    end
  end

  describe 'authorization on profile_id' do
    let(:report_permission_role) { create(:role).tap { |r| r.permission_grant('report') } }
    let(:profile_role)           { create(:role, active: true) }
    let!(:restricted_profile)    { create(:report_profile, roles: [profile_role]) }

    it 'returns not found for unauthorized profile_id' do
      user = create(:agent, roles: [report_permission_role])
      authenticated_as(user)

      post '/api/v1/reports/generate', params: {
        metric:     'count',
        year:       today.year,
        timeRange:  'year',
        profile_id: restricted_profile.id,
        backends:   { 'count::created': true }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq('The reporting profile could not be found.')
    end
  end
end

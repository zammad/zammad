# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'iCal endpoints', type: :request do
  context 'with no existing session' do
    it 'gives HTTP Basic auth prompt (#3064)' do
      get '/ical/tickets'

      expect(response.body).to eq("HTTP Basic: Access denied.\n")
    end
  end

  context 'with basic auth as agent' do
    let(:password)   { Faker::Internet.password }
    let(:user)       { create(:agent, password: password) }
    let(:basic_auth) { ActionController::HttpAuthentication::Basic.encode_credentials(user.email, password) }

    context 'when two-factor auth is disabled' do
      it 'returns 200 OK' do
        get '/ical/tickets', headers: { 'Authorization' => basic_auth }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when two-factor auth is enabled' do
      before do
        Setting.set('two_factor_authentication_enforce_role_ids', [])
        Setting.set('two_factor_authentication_method_authenticator_app', true)
        create(:user_two_factor_preference, :authenticator_app, user: user)
      end

      it 'returns 200 OK' do
        get '/ical/tickets', headers: { 'Authorization' => basic_auth }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'time zone', authenticated_as: :user do
    let(:group) { create(:group) }
    let(:user)  { create(:agent) }

    before do
      user.groups << group

      create(:ticket, group: group, owner: user, state_name: 'open', pending_time: 1.day.ago)
    end

    it 'returns zero offset time if no time zone set' do
      get '/ical/tickets'

      expect(response.body).to match %r{DTSTART:\d{8}T0{6}Z}
    end

    it 'returns selected time zone' do
      Setting.set 'timezone_default', 'Europe/Vilnius'

      get '/ical/tickets'

      expect(response.body).to match %r{DTSTART;TZID=Europe/Vilnius:\d{8}T0{6}}
    end
  end

  # https://github.com/zammad/zammad/issues/3962
  context 'with request method PROPFIND', authenticated_as: :user do
    let(:user) { create(:agent) }

    it 'contains correct request method' do
      get '/ical/tickets', headers: { 'REQUEST_METHOD' => 'PROPFIND' }

      expect(response.request.request_method).to eq('PROPFIND')
    end

    it 'returns the desired calendar file' do
      get '/ical/tickets', headers: { 'REQUEST_METHOD' => 'PROPFIND' }

      expect(response.body).to match(%r{BEGIN:VCALENDAR})
    end
  end

  describe 'methods', authenticated_as: :user do
    let(:group)    { create(:group) }
    let(:user)     { create(:agent) }
    let(:ticket_1) { create(:ticket, title: SecureRandom.uuid, group: group, owner: user, state_name: 'open') }
    let(:ticket_2) { create(:ticket, title: SecureRandom.uuid, group: group, owner: user, state_name: 'pending reminder', pending_time: 1.day.from_now) }

    before do
      user.groups << group
      ticket_1
      ticket_2
    end

    it 'returns open tickets', :aggregate_failures do
      get '/ical/tickets/new_open'

      expect(response.body).to include(ticket_1.title)
      expect(response.body).not_to include(ticket_2.title)
    end

    it 'returns pending tickets', :aggregate_failures do
      get '/ical/tickets/pending'

      expect(response.body).not_to include(ticket_1.title)
      expect(response.body).to include(ticket_2.title)
    end

    it 'raises error on unknown method', :aggregate_failures do
      get '/ical/tickets/xxx'

      expect(json_response['error']).to eq('An unknown method name was requested.')
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

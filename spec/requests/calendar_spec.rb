# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Calendars', type: :request do

  let(:admin) do
    create(:admin)
  end

  describe 'request handling' do

    it 'does calendar index with nobody' do
      get '/api/v1/calendars', as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Authentication required')

      get '/api/v1/calendars_init', as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Authentication required')

      get '/api/v1/calendars/timezones', as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Authentication required')
    end

    it 'does calendar index with admin' do
      authenticated_as(admin)
      get '/api/v1/calendars', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy
      expect(json_response.count).to eq(1)

      get '/api/v1/calendars?expand=true', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy
      expect(json_response.count).to eq(1)

      get '/api/v1/calendars?full=true', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['record_ids']).to be_truthy
      expect(json_response['record_ids'].count).to eq(1)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']).to be_present

      # index
      get '/api/v1/calendars_init', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['record_ids']).to be_truthy
      expect(json_response['ical_feeds']).to be_truthy
      expect(json_response['ical_feeds']['https://www.google.com/calendar/ical/da.danish%23holiday%40group.v.calendar.google.com/public/basic.ics']).to eq('Denmark')
      expect(json_response['ical_feeds']['https://www.google.com/calendar/ical/de.austrian%23holiday%40group.v.calendar.google.com/public/basic.ics']).to eq('Austria')
      expect(json_response['timezones']).to be_truthy
      expect(json_response['timezones']['Africa/Johannesburg']).to eq(2)
      expect(json_response['timezones']['America/Sitka']).to be_between(-9, -8)
      expect(json_response['timezones']['Europe/Berlin']).to be_between(1, 2)
      expect(json_response['assets']).to be_truthy

      # timezones
      get '/api/v1/calendars/timezones', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['timezones']).to be_a(Hash)
      expect(json_response['timezones']['America/New_York']).to be_truthy
    end
  end

  describe 'Removing calendars via UI and API does not check for references #3845', authenticated_as: -> { user } do
    let(:calendar) { create(:calendar) }
    let(:sla)      { create(:sla, calendar: calendar) }
    let(:user)     { create(:admin) }

    before do
      sla
    end

    it 'does return reference error on delete if related objects exist' do
      delete "/api/v1/calendars/#{calendar.id}", params: {}, as: :json
      expect(json_response['error']).to eq("Can't delete, object has references.")
    end
  end
end

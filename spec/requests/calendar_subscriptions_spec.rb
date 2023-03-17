# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'iCal endpoints', type: :request do
  context 'with no existing session' do
    it 'gives HTTP Basic auth prompt (#3064)' do
      get '/ical/tickets'

      expect(response.body).to eq("HTTP Basic: Access denied.\n")
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
end

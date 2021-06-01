# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'iCal endpoints', type: :request do
  context 'with no existing session' do
    it 'gives HTTP Basic auth prompt (#3064)' do
      get '/ical/tickets'

      expect(response.body).to eq("HTTP Basic: Access denied.\n")
    end
  end
end

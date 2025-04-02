# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'SystemReport', authenticated_as: -> { user }, type: :request do
  describe 'returns System Report' do
    let(:user) { create(:admin) }

    it 'includes version information' do
      get '/api/v1/system_report', params: {}, as: :json
      expect(json_response['fetch']['system_report']).to include('Version' => Version.get)
    end
  end

  describe 'returns System Report Plugins' do
    let(:user) { create(:admin) }

    it 'includes plugins information' do
      get '/api/v1/system_report/plugins', params: {}, as: :json
      expect(json_response['plugins']).to eq(SystemReport.plugins)
    end
  end
end

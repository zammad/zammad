# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'ImportZendesk', :aggregate_failures, authenticated_as: false, set_up: false, type: :request do
  let(:action)   { nil }
  let(:endpoint) { "/api/v1/import/zendesk/#{action}" }

  describe 'GET /api/v1/import/zendesk/import_status' do
    let(:action) { 'import_status' }

    it 'returns import job status when job exists and not finished' do
      create(:import_job, name: 'Import::Zendesk', finished_at: nil)

      get endpoint, as: :json
      expect(json_response['name']).to eq('Import::Zendesk')
      expect(json_response['finished_at']).to be_nil
    end

    it 'returns setup_done when no job exists' do
      get endpoint, as: :json
      expect(json_response['setup_done']).to be true
    end

    it 'returns setup_done when job is finished' do
      create(:import_job, name: 'Import::Zendesk', finished_at: 1.hour.ago)

      get endpoint, as: :json
      expect(json_response['setup_done']).to be true
    end
  end
end

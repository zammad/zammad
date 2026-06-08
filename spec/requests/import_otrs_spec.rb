# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'ImportOtrs', authenticated_as: false, set_up: false, type: :request do
  let(:action)   { nil }
  let(:endpoint) { "/api/v1/import/otrs/#{action}" }

  describe 'GET /api/v1/import/otrs/import_status' do
    let(:action) { 'import_status' }

    it 'returns import status from Import::OTRS.status_bg when in_progress' do
      allow(Import::OTRS).to receive(:status_bg).and_return({ result: 'in_progress' })

      get endpoint, as: :json
      expect(json_response).to eq({ 'result' => 'in_progress' })
    end

    it 'returns setup_done when import is done' do
      allow(Import::OTRS).to receive(:status_bg).and_return({ result: 'import_done' })

      get endpoint, as: :json
      expect(json_response['setup_done']).to be true
    end
  end
end

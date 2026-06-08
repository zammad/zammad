# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'ImportKayako', :aggregate_failures, authenticated_as: false, required_envs: %w[IMPORT_KAYAKO_ENDPOINT_SUBDOMAIN], set_up: false, type: :request do
  let(:action)   { nil }
  let(:endpoint) { "/api/v1/import/kayako/#{action}" }

  describe 'POST /api/v1/import/kayako/url_check', :use_vcr do
    let(:action) { 'url_check' }

    it 'check invalid subdomain' do
      post endpoint, params: { url: 'https://reallybadexample.kayako.com' }, as: :json
      expect(json_response['result']).to eq('invalid')
    end

    it 'check valid subdomain' do
      post endpoint, params: { url: "https://#{ENV['IMPORT_KAYAKO_ENDPOINT_SUBDOMAIN']}.kayako.com" }, as: :json
      expect(json_response['result']).to eq('ok')
    end
  end

  describe 'GET /api/v1/import/kayako/import_status' do
    let(:action) { 'import_status' }

    it 'returns import job status when job exists and not finished' do
      create(:import_job, name: 'Import::Kayako', finished_at: nil)

      get endpoint, as: :json
      expect(json_response['name']).to eq('Import::Kayako')
      expect(json_response['finished_at']).to be_nil
    end

    it 'returns setup_done when no job exists' do
      get endpoint, as: :json
      expect(json_response['setup_done']).to be true
    end

    it 'returns setup_done when job is finished' do
      create(:import_job, name: 'Import::Kayako', finished_at: 1.hour.ago)

      get endpoint, as: :json
      expect(json_response['setup_done']).to be true
    end
  end
end

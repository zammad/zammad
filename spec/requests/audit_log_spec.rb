# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AuditLog', type: :request do
  let(:admin) { create(:admin) }

  describe 'source ip tracking' do
    let(:setting) { Setting.find_by(name: 'product_name') }

    before do
      authenticated_as(admin)
      put "/api/v1/settings/#{setting.id}", params: { state_current: { value: 'Some product' } }, as: :json
    end

    it 'stores the request ip on audit log entries' do
      expect(AuditLog.find_by(auditable_type: 'Setting', auditable_id: setting.id, action_type: 'update').source_ip)
        .to eq('127.0.0.1')
    end
  end

  describe 'authorization' do
    let(:agent)     { create(:agent) }
    let(:audit_log) { create(:audit_log) }

    context 'when user has no admin.audit_log permission' do
      before do
        authenticated_as(agent)
      end

      it 'forbids index' do
        get '/api/v1/audit_logs', as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'forbids show' do
        get "/api/v1/audit_logs/#{audit_log.id}", as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'forbids search' do
        post '/api/v1/audit_logs/search', params: { query: '*' }, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user has admin.audit_log permission' do
      before do
        authenticated_as(admin)
      end

      it 'allows index' do
        get '/api/v1/audit_logs', as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'allows show' do
        get "/api/v1/audit_logs/#{audit_log.id}", as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'allows search' do
        post '/api/v1/audit_logs/search', params: { query: '*' }, as: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

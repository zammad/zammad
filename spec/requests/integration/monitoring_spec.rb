# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Monitoring', authenticated_as: :admin, type: :request do
  let(:access_token) { SecureRandom.urlsafe_base64(64) }
  let(:admin)        { create(:admin, groups: Group.all) }
  let(:agent)        { create(:agent, groups: Group.all) }

  before do
    Setting.set('monitoring_token', access_token)
  end

  def make_call(params = {})
    send(method, url, params: params, as: :json)
  end

  shared_examples 'accessible' do |token:, admin:, agent:|
    it "verify token #{token ? 'allows' : 'denies'} access", authenticated_as: false do
      make_call({ token: access_token })

      expect(response).to have_http_status(token ? :success : :forbidden)
    end

    if token
      it 'verify wrong token denies access', authenticated_as: false do
        make_call({ token: 'asd' })

        expect(response).to have_http_status(:forbidden)
      end
    end

    it "verify admin #{admin ? 'allows' : 'denies'} access", authenticated_as: :admin do
      make_call

      expect(response).to have_http_status(admin ? :success : :forbidden)
    end

    it "verify agent #{agent ? 'allows' : 'denies'} access", authenticated_as: :agent do
      make_call

      expect(response).to have_http_status(agent ? :success : :forbidden)
    end
  end

  describe '#health_check' do
    let(:url)    { '/api/v1/monitoring/health_check' }
    let(:method) { 'get' }

    let(:successful_response) do
      resp = MonitoringHelper::HealthChecker::Response.new
      resp.issues << :issues
      resp.actions << :actions

      resp
    end

    it_behaves_like 'accessible', token: true, admin: true, agent: false

    it 'returns matching token' do
      make_call

      expect(json_response['token']).to eq access_token
    end

    it 'returns health status' do
      allow_any_instance_of(MonitoringHelper::HealthChecker)
        .to receive(:response)
        .and_return(successful_response)

      make_call

      expect(json_response).to include('healthy' => false, 'message' => 'issues', 'issues' => ['issues'], 'actions' => ['actions'])
    end
  end

  describe '#status' do
    let(:url)    { '/api/v1/monitoring/status' }
    let(:method) { 'get' }

    it_behaves_like 'accessible', token: true, admin: true, agent: false

    it 'returns status' do
      allow_any_instance_of(MonitoringHelper::Status)
        .to receive(:fetch_status)
        .and_return({ status_hash: :sample })

      make_call

      expect(json_response).to include('status_hash' => 'sample')
    end
  end

  describe '#amount_check' do
    let(:url)    { '/api/v1/monitoring/amount_check' }
    let(:method) { 'get' }

    before do
      allow_any_instance_of(MonitoringHelper::AmountCheck).to receive(:check_amount).and_return({})
    end

    it_behaves_like 'accessible', token: true, admin: true, agent: false

    it 'returns amount' do
      allow_any_instance_of(MonitoringHelper::AmountCheck)
        .to receive(:check_amount)
        .and_return({ amount_hash: :sample })

      make_call

      expect(json_response).to include('amount_hash' => 'sample')
    end
  end

  describe '#token' do
    let(:url)    { '/api/v1/monitoring/token' }
    let(:method) { 'post' }

    it_behaves_like 'accessible', token: false, admin: true, agent: false

    it 'returns token' do
      make_call

      expect(json_response).to include('token' => match(%r{^\S{54}$}))
    end

    it 'sets new token' do
      expect { make_call }.to change { Setting.get('monitoring_token') }.from(access_token)
    end
  end

  describe '#restart_failed_jobs' do
    let(:url)    { '/api/v1/monitoring/restart_failed_jobs' }
    let(:method) { 'post' }

    it_behaves_like 'accessible', token: false, admin: true, agent: false

    it 'returns token' do
      allow(Scheduler).to receive(:restart_failed_jobs)
      make_call
      expect(Scheduler).to have_received(:restart_failed_jobs)
    end
  end
end

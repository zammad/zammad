# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe GitLab::HttpClient, :aggregate_failures do
  subject(:client) { described_class.new(endpoint, api_token) }

  let(:endpoint)  { 'https://git.example.com/api/graphql' }
  let(:api_token) { 't0k3N' }

  shared_examples 'logging the request without the token' do
    it 'sends the token but keeps it out of the http log' do
      expect { request }.to change(HttpLog, :count).by(1)

      expect(WebMock).to have_requested(:any, %r{git\.example\.com}).with(headers: { 'PRIVATE-TOKEN' => api_token })

      log = HttpLog.last
      expect(log.facility).to eq('GitLab')
      expect(log.request['content']).to include('private-token: [FILTERED]')
      expect(log.request.to_s).not_to include(api_token)
    end
  end

  describe '#perform' do
    let(:request) { client.perform({ query: '{ currentUser { username } }' }) }

    before do
      stub_request(:post, endpoint).to_return(status: 200, body: '{"data":{}}', headers: { 'Content-Type' => 'application/json' })
    end

    include_examples 'logging the request without the token'
  end

  describe '#perform_rest_get_request' do
    let(:request) { client.perform_rest_get_request({ fullpath: 'group/project', issue_id: 1 }) }

    before do
      stub_request(:get, 'https://git.example.com/api/v4/projects/group%2Fproject/issues/1').to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    end

    include_examples 'logging the request without the token'
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MicrosoftGraph, :aggregate_failures do
  %w[global us_gov].each do |cloud|
    context "with #{cloud} cloud" do
      let(:client)   { described_class.new(access_token: 'token', mailbox: 'user@example.com', cloud: cloud) }
      let(:host)     { MicrosoftCloud.new(cloud).graph_host }
      let(:page_url) { "https://#{host}/v1.0/users/user@example.com/messages/?$skiptoken=next" }

      it 'sends its bearer token to the configured Graph endpoint and follows its next page' do
        first = stub_request(:get, %r{https://#{Regexp.escape(host)}/v1.0/users/user@example.com/messages/})
          .with(headers: { 'Authorization' => 'Bearer token' }, query: hash_including('$count' => 'true'))
          .to_return(body: { value: [{ id: 'first' }], '@odata.nextLink' => page_url, '@odata.count' => 2 }.to_json, headers: { 'Content-Type' => 'application/json' })
        second = stub_request(:get, page_url)
          .with(headers: { 'Authorization' => 'Bearer token' })
          .to_return(body: { value: [{ id: 'second' }] }.to_json, headers: { 'Content-Type' => 'application/json' })

        expect(client.list_messages[:items].pluck(:id)).to eq(%w[first second])
        expect(first).to have_been_requested.once
        expect(second).to have_been_requested.once
      end

      it 'rejects a next page targeting another cloud before sending the token' do
        foreign_url = 'https://example.com/v1.0/users/user@example.com/messages/'
        stub_request(:get, %r{https://#{Regexp.escape(host)}/v1.0/users/user@example.com/messages/})
          .to_return(body: { value: [], '@odata.nextLink' => foreign_url }.to_json, headers: { 'Content-Type' => 'application/json' })

        expect { client.list_messages }.to raise_error(ArgumentError, 'Invalid Microsoft Graph pagination URL.')
        expect(a_request(:get, foreign_url)).not_to have_been_made
      end
    end
  end

  context 'with the default cloud' do
    let(:client) { described_class.new(access_token: 'token', mailbox: 'user@example.com') }

    %w[http://graph.microsoft.com/v1.0/me https://graph.microsoft.com:444/v1.0/me https://token@graph.microsoft.com/v1.0/me //graph.microsoft.com/v1.0/me https://graph.microsoft.com/beta/me].each do |url|
      it "rejects unsafe pagination URL #{url}" do
        expect { client.send(:request_uri, url) }.to raise_error(ArgumentError)
      end
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MicrosoftGraph, :aggregate_failures do
  it 'posts the destination to Graph and returns the moved message' do
    request = stub_request(:post, 'https://graph.microsoft.com/v1.0/users/mailbox@example.com/messages/message/move')
      .with(headers: { 'Authorization' => 'Bearer token' }, body: { destinationId: 'destination' }.to_json)
      .to_return(status: 201, body: { id: 'moved' }.to_json, headers: { 'Content-Type' => 'application/json' })

    graph = described_class.new(access_token: 'token', mailbox: 'mailbox@example.com')
    expect(graph.move_message('message', 'destination')).to include(id: 'moved')
    expect(request).to have_been_requested.once
  end
end

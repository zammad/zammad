# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::MicrosoftGraphInbound, :aggregate_failures do
  let(:graph)   { instance_double(MicrosoftGraph, list_messages: { items: [], total_count: 0 }) }
  let(:channel) { build_stubbed(:channel) }
  let(:options) { { user: 'user@example.com', shared_mailbox: 'shared@example.com', password: 'token', cloud: 'us_gov' } }

  before do
    allow(MicrosoftGraph).to receive(:new).and_return(graph)
  end

  it 'passes the cloud and shared mailbox to the inbound Graph client' do
    expect(described_class.new.fetch(options, channel)).to include(result: 'ok')
    expect(MicrosoftGraph).to have_received(:new).with(access_token: 'token', mailbox: 'shared@example.com', cloud: 'us_gov')
  end

  it 'passes the cloud and shared mailbox to the outbound Graph client' do
    allow(graph).to receive(:send_message)
    mail = Mail.new
    Channel::Driver::MicrosoftGraphOutbound::MicrosoftGraphOutboundClient.new(options).deliver!(mail)

    expect(MicrosoftGraph).to have_received(:new).with(access_token: 'token', mailbox: 'shared@example.com', cloud: 'us_gov')
    expect(graph).to have_received(:send_message).with(mail)
  end
end

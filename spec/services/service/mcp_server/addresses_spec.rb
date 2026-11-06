# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::MCPServer::Addresses, :aggregate_failures do
  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'zammad.example.com')
    Setting.set('alternative_fqdn', 'support.example.com:8443')
  end

  it 'accepts Zammad\'s configured addresses and the loopback hosts' do
    expect(described_class.allowed?(host: 'zammad.example.com', origin: nil)).to be(true)
    expect(described_class.allowed?(host: 'ZAMMAD.example.com:443', origin: nil)).to be(true)
    expect(described_class.allowed?(host: 'support.example.com:8443', origin: nil)).to be(true)
    expect(described_class.allowed?(host: 'localhost:3000', origin: nil)).to be(true)
    expect(described_class.allowed?(host: '[::1]:3000', origin: nil)).to be(true)
    expect(described_class.allowed?(host: nil, origin: nil)).to be(true)
  end

  it 'refuses another host, as a rebound name would be' do
    expect(described_class.allowed?(host: 'attacker.example', origin: nil)).to be(false)
  end

  it 'accepts the configured origins and the same origin, and refuses others' do
    expect(described_class.allowed?(host: 'zammad.example.com', origin: 'https://zammad.example.com')).to be(true)
    expect(described_class.allowed?(host: 'localhost:3000', origin: 'http://localhost:3000')).to be(true)
    expect(described_class.allowed?(host: 'zammad.example.com', origin: 'https://attacker.example')).to be(false)
    expect(described_class.allowed?(host: 'zammad.example.com', origin: 'null')).to be(false)
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationCable::Connection, 'origin configuration' do
  subject(:origin_allowed) { connection.send(:allow_request_origin?) }

  let(:config)           { ActionCable::Server::Configuration.new }
  let(:connection)       { described_class.allocate }
  let(:server)           { instance_double(ActionCable::Server::Base, config: config) }
  let(:alternative_fqdn) { 'tenant.example.org' }
  let(:origin)           { 'https://tenant.example.org' }
  let(:host)             { 'upstream.internal' }

  before do
    allow(Setting).to receive(:get).and_call_original
    allow(Setting).to receive(:get).with('http_type').and_return('https')
    allow(Setting).to receive(:get).with('fqdn').and_return('support.example.org')
    allow(Setting).to receive(:get).with('alternative_fqdn').and_return(alternative_fqdn)
    allow(Rails.env).to receive(:production?).and_return(true)
    allow(Rails.application.config).to receive(:action_cable).and_return(config)
    allow(Rails.application.reloader).to receive(:to_prepare).and_yield
    allow(Zammad::Service::Redis).to receive(:new).and_return(instance_double(Zammad::Service::Redis, ping: true))

    load Rails.root.join('config/initializers/zzz_action_cable_preferences.rb')

    allow(connection).to receive_messages(
      server: server,
      logger: Rails.logger,
      env:    { 'HTTP_ORIGIN' => origin, 'HTTP_HOST' => host, 'rack.url_scheme' => 'https' },
    )
  end

  it 'accepts the alternative origin when the proxy rewrites the host' do
    expect(origin_allowed).to be true
  end

  context 'with the canonical origin' do
    let(:origin) { 'https://support.example.org' }

    it { is_expected.to be true }
  end

  context 'with a same-origin request outside the explicit allowlist' do
    let(:origin) { 'https://another.example.org' }
    let(:host)   { 'another.example.org' }

    it { is_expected.to be true }
  end

  context 'with a foreign origin' do
    let(:origin) { 'https://evil.example.org' }

    it { is_expected.to be false }
  end
end

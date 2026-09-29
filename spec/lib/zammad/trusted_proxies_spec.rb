# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::TrustedProxies, :aggregate_failures do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('RAILS_TRUSTED_PROXIES').and_return(env_value)
  end

  describe '.fetch' do
    # IPAddr#== ignores the prefix length, so compare the printed range instead.
    let(:ranges) { described_class.fetch.map { |proxy| "#{proxy}/#{proxy.prefix}" } }

    context 'without env setting' do
      let(:env_value) { nil }

      it 'falls back to localhost' do
        expect(described_class.fetch).to all(be_a(IPAddr))
        expect(ranges).to eq(['127.0.0.1/32', '::1/128'])
      end
    end

    context 'with legacy env setting in Ruby syntax' do
      let(:env_value) { "['1.2.3.4']" }

      it 'parses correctly' do
        expect(described_class.fetch).to all(be_a(IPAddr))
        expect(ranges).to eq(['1.2.3.4/32'])
      end
    end

    context 'with legacy env setting in Ruby syntax containing address ranges' do
      let(:env_value) { "['127.0.0.1','::1','192.168.66.0/24','172.18.0.0/16']" }

      it 'parses the ranges' do
        expect(ranges).to eq(['127.0.0.1/32', '::1/128', '192.168.66.0/24', '172.18.0.0/16'])
      end

      it 'matches addresses inside the ranges' do
        expect(described_class.fetch.any? { |proxy| proxy.include?('192.168.66.1') }).to be(true)
        expect(described_class.fetch.any? { |proxy| proxy.include?('192.168.67.1') }).to be(false)
      end

      # Docker stack: an external reverse proxy forwards to the nginx container, which appends
      #   the proxy's address to X-Forwarded-For before passing the request on to Rails.
      it 'lets Rails resolve the client address of a request through proxies in the ranges' do
        remote_ip = nil
        app       = lambda do |env|
          remote_ip = ActionDispatch::Request.new(env).remote_ip
          [200, {}, []]
        end

        middleware = ActionDispatch::RemoteIp.new(app, true, described_class.fetch)
        env        = Rack::MockRequest.env_for('/', 'REMOTE_ADDR' => '172.18.0.5', 'HTTP_X_FORWARDED_FOR' => '203.0.113.7, 192.168.66.1')

        middleware.call(env)

        expect(remote_ip).to eq('203.0.113.7')
      end
    end

    context 'with valid IP addresses and hostnames' do
      let(:env_value) { '1.2.3.4/24,::2,proxy.example.com' }

      before do
        allow(Resolv).to receive(:getaddresses).with('proxy.example.com').and_return(['5.6.7.8', '::3'])
      end

      it 'parses correctly' do
        expect(described_class.fetch).to all(be_a(IPAddr))
        expect(ranges).to eq(['1.2.3.0/24', '::2/128', '5.6.7.8/32', '::3/128'])
      end
    end

    context 'with a hostname resolving to an address IPAddr rejects' do
      let(:env_value) { 'proxy.example.com' }

      before do
        allow(described_class).to receive(:warn)
        allow(Resolv).to receive(:getaddresses).with('proxy.example.com').and_return(['010.0.0.1', '5.6.7.8'])
      end

      it 'keeps the valid address and warns about the other one' do
        expect(ranges).to eq(['5.6.7.8/32'])
        expect(described_class).to have_received(:warn).with(include("'010.0.0.1'")).once
      end
    end

    context 'with invalid IP addresses and hostnames' do
      let(:env_value) { '1.2.3.4.5,:::::2,nonexisting' }

      before do
        allow(described_class).to receive(:warn)
      end

      it 'filters everything out' do
        expect(described_class.fetch).to be_empty
        expect(described_class).to have_received(:warn).exactly(3)
      end
    end
  end
end

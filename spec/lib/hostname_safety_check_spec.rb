# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HostnameSafetyCheck do
  let(:validate)         { described_class.validate!(hostname, allow_private:, allow_loopback:, allow_link_local:) }
  let(:resolved_ip)      { hostname }
  let(:allow_private)    { false }
  let(:allow_loopback)   { false }
  let(:allow_link_local) { false }

  before do
    allow(IPSocket).to receive(:getaddress).with(hostname).and_return(resolved_ip)
  end

  context 'when hostname is safe' do
    let(:hostname) { 'zammad.org' }
    let(:resolved_ip) { '116.203.82.166' }

    it 'returns true' do
      expect(validate).to be(true)
    end
  end

  context 'when hostname points to a private IP' do
    let(:hostname) { 'private.example.com' }
    let(:resolved_ip) { '10.0.0.1' }

    context 'when allowing private IPs' do
      let(:allow_private) { true }

      it 'returns true' do
        expect(validate).to be(true)
      end
    end

    context 'when disallowing private IPs' do
      let(:allow_private) { false }

      it 'raises a SafetyError' do
        expect { validate }
          .to raise_error(HostnameSafetyCheck::PrivateIpError, %r{The hostname is a private IP})
      end
    end
  end

  context 'when hostname points to a loopback IP' do
    let(:hostname)    { 'localhost' }
    let(:resolved_ip) { '127.0.0.1' }

    context 'when allowing loopback IPs' do
      let(:allow_loopback) { true }

      it 'returns true' do
        expect(validate).to be(true)
      end
    end

    context 'when disallowing loopback IPs' do
      it 'raises a SafetyError' do
        expect { validate }
          .to raise_error(HostnameSafetyCheck::LoopbackIpError, %r{The hostname is a loopback IP})
      end
    end
  end

  context 'when hostname points to a link-local IP' do
    let(:hostname)    { 'linklocal.example.com' }
    let(:resolved_ip) { '169.254.123.45' }

    context 'when allowing link-local IPs' do
      let(:allow_link_local) { true }

      it 'returns true' do
        expect(validate).to be(true)
      end
    end

    context 'when disallowing link-local IPs' do
      it 'raises a SafetyError' do
        expect { validate }
          .to raise_error(HostnameSafetyCheck::LinkLocalIpError, %r{The hostname is a link-local IP})
      end
    end
  end
end

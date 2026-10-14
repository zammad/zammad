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

    it 'returns the resolved IP' do
      expect(validate).to eq(resolved_ip)
    end
  end

  context 'when hostname points to a private IP' do
    let(:hostname) { 'private.example.com' }
    let(:resolved_ip) { '10.0.0.1' }

    context 'when allowing private IPs' do
      let(:allow_private) { true }

      it 'returns the resolved IP' do
        expect(validate).to eq(resolved_ip)
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

      it 'returns the resolved IP' do
        expect(validate).to eq(resolved_ip)
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

      it 'returns the resolved IP' do
        expect(validate).to eq(resolved_ip)
      end
    end

    context 'when disallowing link-local IPs' do
      it 'raises a SafetyError' do
        expect { validate }
          .to raise_error(HostnameSafetyCheck::LinkLocalIpError, %r{The hostname is a link-local IP})
      end
    end
  end

  # An IPv4 address may be resolved in IPv6 notation, which must not change what it counts as.
  context 'when hostname points to a link-local IP in IPv6 notation' do
    let(:hostname)    { 'linklocal.example.com' }
    let(:resolved_ip) { '::ffff:169.254.169.254' }

    context 'when allowing link-local IPs' do
      let(:allow_link_local) { true }

      it 'returns the resolved IP' do
        expect(validate).to eq(resolved_ip)
      end
    end

    context 'when disallowing link-local IPs' do
      it 'raises a SafetyError' do
        expect { validate }
          .to raise_error(HostnameSafetyCheck::LinkLocalIpError, %r{The hostname is a link-local IP})
      end
    end
  end

  context 'when hostname points to a link-local IP in IPv4-compatible IPv6 notation' do
    let(:hostname)    { 'linklocal.example.com' }
    let(:resolved_ip) { '::169.254.169.254' }

    it 'raises a SafetyError' do
      expect { validate }
        .to raise_error(HostnameSafetyCheck::LinkLocalIpError, %r{The hostname is a link-local IP})
    end
  end

  context 'when hostname points to a loopback IP in IPv6 notation' do
    let(:hostname)    { 'localhost' }
    let(:resolved_ip) { '::ffff:127.0.0.1' }

    it 'raises a SafetyError' do
      expect { validate }
        .to raise_error(HostnameSafetyCheck::LoopbackIpError, %r{The hostname is a loopback IP})
    end
  end

  context 'when hostname points to a private IP in IPv6 notation' do
    let(:hostname)    { 'private.example.com' }
    let(:resolved_ip) { '::ffff:10.0.0.1' }

    context 'when allowing private IPs' do
      let(:allow_private) { true }

      it 'returns the resolved IP' do
        expect(validate).to eq(resolved_ip)
      end
    end

    context 'when disallowing private IPs' do
      it 'raises a SafetyError' do
        expect { validate }
          .to raise_error(HostnameSafetyCheck::PrivateIpError, %r{The hostname is a private IP})
      end
    end
  end

  context 'when hostname points to a unique local IPv6 address' do
    let(:hostname)    { 'private.example.com' }
    let(:resolved_ip) { 'fd12:3456:789a::1' }

    context 'when allowing private IPs' do
      let(:allow_private) { true }

      it 'returns the resolved IP' do
        expect(validate).to eq(resolved_ip)
      end
    end

    context 'when disallowing private IPs' do
      it 'raises a SafetyError' do
        expect { validate }
          .to raise_error(HostnameSafetyCheck::PrivateIpError, %r{The hostname is a private IP})
      end
    end
  end

  # A unique local address like any other, so allowing private IPs must not admit it.
  context 'when hostname points to the metadata service of a cloud provider' do
    let(:hostname)    { 'metadata.example.com' }
    let(:resolved_ip) { 'fd00:ec2::254' }

    it 'raises a SafetyError' do
      expect { validate }
        .to raise_error(HostnameSafetyCheck::MetadataIpError, %r{The hostname is a cloud metadata service})
    end

    context 'when allowing every kind of address' do
      let(:allow_private)    { true }
      let(:allow_loopback)   { true }
      let(:allow_link_local) { true }

      it 'still raises a SafetyError' do
        expect { validate }
          .to raise_error(HostnameSafetyCheck::MetadataIpError)
      end
    end
  end

  describe '.safe_addresses' do
    let(:hostname)  { 'dualstack.example.com' }
    let(:addresses) { ['2001:db8::1', '203.0.113.10', '169.254.169.254', 'fd00:ec2::254', '203.0.113.10'] }

    before do
      allow(Addrinfo).to receive(:getaddrinfo)
        .with(hostname, nil, nil, :STREAM)
        .and_return(addresses.map { |address| Addrinfo.tcp(address, 0) })
    end

    it 'returns the distinct safe addresses in resolver order' do
      expect(described_class.safe_addresses(hostname)).to eq(['2001:db8::1', '203.0.113.10'])
    end

    it 'applies the given options' do
      expect(described_class.safe_addresses(hostname, allow_link_local: true))
        .to eq(['2001:db8::1', '203.0.113.10', '169.254.169.254'])
    end

    context 'when the hostname cannot be resolved' do
      before do
        allow(Addrinfo).to receive(:getaddrinfo).and_raise(SocketError)
      end

      it 'returns no addresses' do
        expect(described_class.safe_addresses(hostname)).to eq([])
      end
    end
  end
end

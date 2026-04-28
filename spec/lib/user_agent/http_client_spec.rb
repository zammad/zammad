# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UserAgent::HttpClient do
  let(:instance) { described_class.new(uri, options) }
  let(:uri)      { URI('https://example.com/test') }
  let(:options)  { {} }

  describe '#client' do
    shared_examples 'returns the direct client' do
      it 'returns the direct client' do
        expect(instance.client).not_to be_proxy_class
      end
    end

    shared_examples 'returns the proxy client' do
      it 'returns the proxy client' do
        expect(instance.client).to be_proxy_class
      end
    end

    context 'without proxy configuration' do
      include_examples 'returns the direct client'
    end

    context 'with valid proxy configuration' do
      let(:options) { { 'proxy' => 'proxy.example.com:3128' } }

      include_examples 'returns the proxy client'

      context 'when the address is loopback' do
        let(:uri) { URI('https://localhost/test') }

        include_examples 'returns the direct client'
      end

      context 'when the address is in proxy_no list' do
        let(:options) { super().merge('proxy_no' => 'example.com') }

        include_examples 'returns the direct client'
      end

      context 'when the address is a subdomain of a no-proxy entry starting with a wildcard' do
        let(:uri)     { URI('https://sub.example.com/test') }
        let(:options) { super().merge('proxy_no' => '*.example.com') }

        include_examples 'returns the direct client'
      end

      context 'when the address is a subdomain of a no-proxy entry starting with a dot' do
        let(:uri) { URI('https://sub.example.com/test') }
        let(:options) { super().merge('proxy_no' => '.example.com') }

        include_examples 'returns the proxy client'
      end

      context 'when the address looks like a multi-level wildcard no-proxy entry' do
        let(:uri) { URI('https://sub.other.example.com/test') }
        let(:options) { super().merge('proxy_no' => 'sub.*.example.com') }

        include_examples 'returns the proxy client'
      end

      context 'when proxy is IPv6' do
        let(:options) { { 'proxy' => '[2001:db8::1]:3128' } }

        include_examples 'returns the proxy client'
      end
    end

    context 'with invalid proxy configuration' do
      let(:options) { { 'proxy' => 'invalid_proxy_format' } }

      it 'raises an error' do
        expect { instance.client }.to raise_error(%r{Invalid proxy address})
      end
    end
  end

  describe '#proxy' do
    context 'when given via options' do
      let(:options) { { 'proxy' => 'proxy.example.com:3128' } }

      it 'returns the given value' do
        expect(instance.client).to have_attributes(proxy_address: 'proxy.example.com', proxy_port: '3128')
      end
    end

    context 'when given via settings' do
      before { Setting.set('proxy', 'example.com:3128') }

      it 'returns the given value' do
        expect(instance.client).to have_attributes(proxy_address: 'example.com', proxy_port: '3128')
      end
    end

    context 'when given via both options and settings' do
      let(:options) { { 'proxy' => 'proxy.example.com:3128' } }

      before { Setting.set('proxy', 'example.com:3128') }

      it 'returns the value from options' do
        expect(instance.client).to have_attributes(proxy_address: 'proxy.example.com', proxy_port: '3128')
      end
    end

    context 'when proxy is IPv6' do
      let(:options) { { 'proxy' => '[2001:db8::1]:3128' } }

      it 'returns the given value' do
        expect(instance.client).to have_attributes(proxy_address: '2001:db8::1', proxy_port: '3128')
      end
    end
  end

  describe '#proxy_username' do
    let(:options) { { 'proxy' => 'proxy.example.com:8080' } }

    context 'when given via options' do
      let(:options) { super().merge('proxy_username' => 'user') }

      it 'returns the given value' do
        expect(instance.client).to have_attributes(proxy_user: 'user')
      end
    end

    context 'when given via settings' do
      before { Setting.set('proxy_username', 'user_setting') }

      it 'returns the given value' do
        expect(instance.client).to have_attributes(proxy_user: 'user_setting')
      end
    end

    context 'when given via both options and settings' do
      let(:options) { super().merge('proxy_username' => 'user') }

      before { Setting.set('proxy_username', 'user_setting') }

      it 'returns the value from options' do
        expect(instance.client).to have_attributes(proxy_user: 'user')
      end
    end
  end

  describe '#proxy_password' do
    let(:options) { { 'proxy' => 'proxy.example.com:8080' } }

    context 'when given via options' do
      let(:options) { super().merge('proxy_password' => 'pass') }

      it 'returns the given value' do
        expect(instance.client).to have_attributes(proxy_pass: 'pass')
      end
    end

    context 'when given via settings' do
      before { Setting.set('proxy_password', 'pass_setting') }

      it 'returns the given value' do
        expect(instance.client).to have_attributes(proxy_pass: 'pass_setting')
      end
    end

    context 'when given via both options and settings' do
      let(:options) { super().merge('proxy_password' => 'pass') }

      before { Setting.set('proxy_password', 'pass_setting') }

      it 'returns the value from options' do
        expect(instance.client).to have_attributes(proxy_pass: 'pass')
      end
    end
  end

  describe '.get_client' do
    it 'returns the Net::HTTP instance' do
      expect(described_class.get_client(uri, options).new('example.com')).to be_a(Net::HTTP)
    end
  end
end

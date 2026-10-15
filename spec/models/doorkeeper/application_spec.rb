# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Doorkeeper::Application, type: :model do
  subject(:application) { described_class.new(name: 'Test', redirect_uri: redirect_uri, scopes: '') }

  context 'with an https redirect URI' do
    let(:redirect_uri) { 'https://example.com/callback' }

    it { is_expected.to be_valid }
  end

  context 'with an http redirect URI to a remote host' do
    let(:redirect_uri) { 'http://example.com/callback' }

    it { is_expected.not_to be_valid }
  end

  # RFC 8252 section 7.3: native apps receive the code on the loopback interface.
  context 'with an http loopback redirect URI' do
    %w[
      http://127.0.0.1:8250/callback
      http://[::1]:8250/callback
      http://localhost:8250/callback
    ].each do |uri|
      context "when the redirect URI is #{uri}" do
        let(:redirect_uri) { uri }

        it { is_expected.to be_valid }
      end
    end
  end

  context 'with an http redirect URI to a host that only resembles loopback' do
    %w[
      http://127.0.0.1.example.com/callback
      http://localhost.example.com/callback
    ].each do |uri|
      context "when the redirect URI is #{uri}" do
        let(:redirect_uri) { uri }

        it { is_expected.not_to be_valid }
      end
    end
  end
end

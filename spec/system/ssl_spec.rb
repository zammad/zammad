# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'SSL Verification', :aggregate_failures, authenticated_as: false, type: :system do
  let(:url)                { "https://#{Setting.get('fqdn')}/robots.txt" }
  let(:localhost_autority) { Localhost::Authority.fetch(CAPYBARA_HOSTNAME) }

  context 'without self-signed certificate present' do
    context 'with verify_ssl: true' do
      it 'UserAgent fails' do
        expect(UserAgent.get(url, {}, { verify_ssl: true })).not_to be_success
        expect(UserAgent.get(url, {}, { verify_ssl: true }).error).to include('certificate verify failed (self-signed certificate)')
      end
    end

    context 'without verify_ssl' do
      it 'UserAgent fails' do
        expect(UserAgent.get(url)).not_to be_success
        expect(UserAgent.get(url).error).to include('certificate verify failed (self-signed certificate)')
      end
    end

    context 'with verify_ssl: false' do
      it 'UserAgent succeeds' do
        expect(UserAgent.get(url, {}, { verify_ssl: false })).to be_success
      end
    end

  end

  context 'with self-signed certificate present' do

    before do
      create(:ssl_certificate, certificate: File.read(localhost_autority.certificate_path))
    end

    context 'with verify_ssl: true' do
      it 'UserAgent succeeds' do
        expect(UserAgent.get(url, {}, { verify_ssl: true })).to be_success
      end
    end

    context 'without verify_ssl: true' do
      it 'UserAgent succeeds' do
        expect(UserAgent.get(url)).to be_success
      end
    end

    context 'with verify_ssl: false' do
      it 'UserAgent succeeds' do
        expect(UserAgent.get(url, {}, { verify_ssl: false })).to be_success
      end
    end
  end

end

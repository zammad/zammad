# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > S/MIME', type: :system do

  let(:fixture) { 'smime1@example.com' }

  let!(:certificate) do
    Rails.root.join("spec/fixtures/files/smime/#{fixture}.crt").read
  end
  let!(:private_key) do
    Rails.root.join("spec/fixtures/files/smime/#{fixture}.key").read
  end
  let!(:private_key_secret) do
    Rails.root.join("spec/fixtures/files/smime/#{fixture}.secret").read.strip
  end

  before do
    visit 'system/integration/smime'

    # enable S/MIME
    click 'label[for=setting-switch]'
  end

  context 'when doing basic tests' do
    it 'enabling and adding of public and private key' do

      # add cert
      click '.js-addCertificate'
      fill_in 'Paste Certificate', with: certificate
      click '.js-submit'

      # add private key
      click '.js-addPrivateKey'
      fill_in 'Paste Private Key', with: private_key
      fill_in 'Enter Private Key Secret', with: private_key_secret
      click '.js-submit'

      # check result
      expect(Setting.get('smime_integration')).to be true
      expect(SMIMECertificate.last.fingerprint).to be_present
      expect(SMIMECertificate.last.pem).to be_present
      expect(SMIMECertificate.last.private_key).to be_present
    end

    it 'adding of multiple certificates at once' do
      multiple_certificates = [
        Rails.root.join('spec/fixtures/files/smime/alice@acme.corp+encrypt.crt').read,
        Rails.root.join('spec/fixtures/files/smime/smimedouble@example.com.crt').read,
      ].join

      # add cert
      click '.js-addCertificate'
      fill_in 'Paste Certificate', with: multiple_certificates
      click '.js-submit'

      # wait for ajax
      expect(page).to have_text('alice@acme.corp')
      expect(page).to have_text('smimedouble@example.com')
    end
  end

  context 'Adding private keys allows adding certificates #3727' do
    let(:private_key) do
      Rails.root.join('spec/fixtures/files/smime/issue_3727.key').read.chomp
    end

    let(:private_key_secret) do
      Rails.root.join('spec/fixtures/files/smime/issue_3727.secret').read.chomp
    end

    let(:certificate_fingerprint) do
      Rails.root.join('spec/fixtures/files/smime/issue_3727.fingerprint').read.chomp
    end

    it 'does add public and private key in one file' do

      # add private key
      click '.js-addPrivateKey'
      fill_in 'Paste Private Key', with: private_key
      fill_in 'Enter Private Key Secret', with: private_key_secret
      click '.js-submit'

      # check result
      expect(Setting.get('smime_integration')).to be true
      expect(SMIMECertificate.last.fingerprint).to eq(certificate_fingerprint)
      expect(SMIMECertificate.last.pem).to include('CERTIFICATE')
      expect(SMIMECertificate.last.pem).not_to include('PRIVATE')
      expect(SMIMECertificate.last.private_key).to include('PRIVATE')
      expect(SMIMECertificate.last.private_key).not_to include('CERTIFICATE')
    end
  end
end

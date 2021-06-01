# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > S/MIME', type: :system do

  let(:fixture) { 'smime1@example.com' }

  let!(:certificate) do
    File.read(Rails.root.join("spec/fixtures/smime/#{fixture}.crt"))
  end
  let!(:private_key) do
    File.read(Rails.root.join("spec/fixtures/smime/#{fixture}.key"))
  end
  let!(:private_key_secret) do
    File.read(Rails.root.join("spec/fixtures/smime/#{fixture}.secret")).strip
  end

  before do
    visit 'system/integration/smime'

    # enable S/MIME
    click 'label[for=setting-switch]'
  end

  it 'enabling and adding of public and private key' do

    # add cert
    click '.js-addCertificate'
    fill_in 'Paste Certificate', with: certificate
    click '.js-submit'

    # add private key
    click '.js-addPrivateKey'
    fill_in 'Paste Private Key', with: private_key
    fill_in 'Enter Private Key secret', with: private_key_secret
    click '.js-submit'

    # wait for ajax
    expect(page).to have_css('td', text: 'Including private key')

    # check result
    expect( Setting.get('smime_integration') ).to be true
    expect( SMIMECertificate.last.fingerprint ).to be_present
    expect( SMIMECertificate.last.raw ).to be_present
    expect( SMIMECertificate.last.private_key ).to be_present
  end

  it 'adding of multiple certificates at once' do
    multiple_certificates = [
      File.read(Rails.root.join('spec/fixtures/smime/ChainCA.crt')),
      File.read(Rails.root.join('spec/fixtures/smime/IntermediateCA.crt')),
      File.read(Rails.root.join('spec/fixtures/smime/RootCA.crt')),
    ].join

    # add cert
    click '.js-addCertificate'
    fill_in 'Paste Certificate', with: multiple_certificates
    click '.js-submit'

    # wait for ajax
    expect(page).to have_text('ChainCA')
    expect(page).to have_text('IntermediateCA')
    expect(page).to have_text('RootCA')
  end
end

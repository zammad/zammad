# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > SSL Certificates', type: :system do
  let(:fixture) { 'RootCA' }

  let(:certificate_file)    { Rails.root.join("spec/fixtures/files/smime/#{fixture}.crt") }
  let(:certificate_content) { certificate_file.read }

  describe 'adding a certificate' do
    before do
      visit 'system/security'
      click_on 'SSL Certificates'
      click '.js-addCertificate'
    end

    context 'when given certificate is valid' do
      it 'can be uploaded as a file' do
        in_modal do
          find('[type=file]').attach_file certificate_file

          click_on 'Add'
        end

        expect(page).to have_css("tr[data-id='#{SSLCertificate.last.id}']")
      end

      it 'can be added as a text blob' do
        in_modal do
          fill_in 'Paste Certificate', with: certificate_content

          click_on 'Add'
        end

        expect(page).to have_css("tr[data-id='#{SSLCertificate.last.id}']")
      end
    end

    context 'when given certificate is invalid' do
      let(:fixture) { 'smime1@example.com' }

      it 'shows an error' do
        in_modal do
          fill_in 'Paste Certificate', with: certificate_content

          click_on 'Add'

          expect(page).to have_text('The certificate is not valid for SSL usage.')
        end
      end
    end
  end

  context 'when certificate is added' do
    let(:certificate) { create(:ssl_certificate, certificate: certificate_content) }

    before do
      certificate
      visit 'system/security'
      click_on 'SSL Certificates'
    end

    it 'is listed' do
      within "tr[data-id='#{certificate.id}']" do
        expect(page).to have_text(certificate.subject)
      end
    end

    it 'can be removed' do
      within "tr[data-id='#{certificate.id}']" do
        click '.js-action'
        click '.js-remove'
      end

      in_modal do
        click_on 'Yes'
      end

      expect(page).to have_no_css("tr[data-id='#{certificate.id}']")
    end

    it 'can be downloaded' do
      within "tr[data-id='#{certificate.id}']" do
        click '.js-action'

        expect(page).to have_css('a[download]', text: 'Download Certificate')
      end
    end
  end
end

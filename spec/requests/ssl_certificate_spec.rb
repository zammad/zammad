# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'SSL Certificate', :aggregate_failures, type: :request do

  let(:admin) { create(:admin) }

  before do
    authenticated_as(admin)
  end

  describe '/ssl_certificates' do

    let(:endpoint) { '/api/v1/ssl_certificates' }

    let(:certificate_path) do
      Rails.root.join('spec/fixtures/files/smime/RootCA.crt')
    end
    let(:certificate_string) do
      File.read(certificate_path)
    end

    describe 'POST requests' do

      let(:parsed_certificate) { Certificate::X509::SSL.new(certificate_string) }

      it 'adds certificate by string' do
        expect do
          post endpoint, params: { certificate: certificate_string }, as: :json
        end.to change(SSLCertificate, :count).by(1)

        expect(response).to have_http_status(:created)

        expect(json_response).to include(
          'not_after' => parsed_certificate.not_after.as_json
        )
      end

      it 'adds certificate by file' do
        expect do
          post endpoint, params: { file: Rack::Test::UploadedFile.new(certificate_path, 'text/plain', true) }
        end.to change(SSLCertificate, :count).by(1)

        expect(response).to have_http_status(:created)

        expect(json_response).to include(
          'not_after' => parsed_certificate.not_after.as_json
        )
      end
    end

    describe 'GET requests' do

      let!(:certificate) { create(:ssl_certificate, fixture: 'RootCA') }

      it 'lists certificates' do
        get endpoint, as: :json
        expect(response).to have_http_status(:ok)

        expect(json_response['SSLCertificate'].values.first.keys).to match_array %w[
          id
          subject
          fingerprint
          not_before
          not_after
          created_at
          updated_at
          ca
        ]

        expect(json_response).to include_assets_of certificate
      end
    end

    describe 'DELETE requests' do

      let!(:certificate) { create(:ssl_certificate, fixture: 'RootCA') }

      it 'deletes certificate' do
        expect do
          delete "#{endpoint}/#{certificate.id}", as: :json
        end.to change(SSLCertificate, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end

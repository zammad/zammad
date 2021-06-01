# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Integration SMIME', type: :request do

  let(:admin) { create(:admin) }
  let(:email_address) { 'smime1@example.com' }

  before do
    authenticated_as(admin)
  end

  describe '/integration/smime/certificate' do

    let(:endpoint) { '/api/v1/integration/smime/certificate' }

    let(:certificate_path) do
      Rails.root.join("spec/fixtures/smime/#{email_address}.crt")
    end
    let(:certificate_string) do
      File.read(certificate_path)
    end

    context 'POST requests' do

      let(:parsed_certificate) { SMIMECertificate.parse(certificate_string) }

      it 'adds certificate by string' do
        expect do
          post endpoint, params: { data: certificate_string }, as: :json
        end.to change(SMIMECertificate, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(DateTime.parse(json_response['response'][0]['not_after_at'])).to eq(parsed_certificate.not_after)
      end

      it 'adds certificate by file' do
        expect do
          post endpoint, params: { file: Rack::Test::UploadedFile.new(certificate_path, 'text/plain', true) }
        end.to change(SMIMECertificate, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(DateTime.parse(json_response['response'][0]['not_after_at'])).to eq(parsed_certificate.not_after)
      end
    end

    context 'GET requests' do

      let!(:certificate) { create(:smime_certificate, fixture: email_address) }

      it 'lists certificates' do
        get endpoint, as: :json
        expect(response).to have_http_status(:ok)

        expect(json_response.any? { |e| e['id'] == certificate.id }).to be true
      end
    end

    context 'DELETE requests' do

      let!(:certificate) { create(:smime_certificate, fixture: email_address) }

      it 'deletes certificate' do
        expect do
          delete endpoint, params: { id: certificate.id }, as: :json
        end.to change(SMIMECertificate, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe '/integration/smime/private_key' do

    let(:endpoint) { '/api/v1/integration/smime/private_key' }

    context 'POST requests' do

      let(:private_path) do
        Rails.root.join("spec/fixtures/smime/#{email_address}.key")
      end

      let(:private_string) { File.read(private_path) }

      let(:secret) do
        File.read(Rails.root.join("spec/fixtures/smime/#{email_address}.secret")).strip
      end

      let!(:certificate) { create(:smime_certificate, fixture: email_address) }

      it 'adds by string' do
        expect do
          post endpoint, params: { data: private_string, secret: secret }, as: :json
        end.to change {
          certificate.reload
          certificate.private_key
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['result']).to eq('ok')
      end

      it 'adds by file' do
        expect do
          post endpoint, params: { file: Rack::Test::UploadedFile.new(private_path, 'text/plain', true), secret: secret }
        end.to change {
          certificate.reload
          certificate.private_key
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['result']).to eq('ok')
      end
    end

    context 'DELETE requests' do

      let!(:certificate) { create(:smime_certificate, :with_private, fixture: email_address) }

      it 'deletes private key' do
        expect do
          delete endpoint, params: { id: certificate.id }, as: :json
        end.to change {
          certificate.reload
          certificate.private_key
        }.to(nil)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe '/integration/smime' do

    let(:endpoint) { '/api/v1/integration/smime' }

    context 'POST requests' do

      let(:system_email_address) { create(:email_address, email: email_address) }
      let(:group) { create(:group, email_address: system_email_address) }

      let(:search_query) do
        {
          article: {
            to: email_address,
          },
          ticket:  {
            group_id: group.id,
          },
        }
      end

      context 'certificate not present' do
        it 'does not find non existing certificates' do
          post endpoint, params: search_query, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response['encryption']['success']).to eq(false)
          expect(json_response['encryption']['comment']).to include(email_address)
          expect(json_response['sign']['success']).to eq(false)
          expect(json_response['sign']['comment']).to include(email_address)
        end
      end

      context 'certificate present' do

        before do
          create(:smime_certificate, :with_private, fixture: email_address)
        end

        it 'finds existing certificate' do
          post endpoint, params: search_query, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response['encryption']['success']).to eq(true)
          expect(json_response['encryption']['comment']).to include(email_address)
          expect(json_response['sign']['success']).to eq(true)
          expect(json_response['sign']['comment']).to include(email_address)
        end

        context 'but expired' do
          let(:email_address) { 'expiredsmime1@example.com' }

          it 'finds existing certificate with comment' do
            post endpoint, params: search_query, as: :json

            expect(response).to have_http_status(:ok)
            expect(json_response['encryption']['success']).to eq(false)
            expect(json_response['encryption']['comment']).to include(email_address).and include('expired')
            expect(json_response['sign']['success']).to eq(false)
            expect(json_response['sign']['comment']).to include(email_address).and include('expired')
          end
        end
      end
    end
  end
end

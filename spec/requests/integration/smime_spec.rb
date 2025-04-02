# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Integration SMIME', type: :request do

  let(:admin)         { create(:admin) }
  let(:email_address) { 'smime1@example.com' }

  before do
    authenticated_as(admin)
  end

  describe '/integration/smime/certificate' do

    let(:endpoint) { '/api/v1/integration/smime/certificate' }

    let(:certificate_path) do
      Rails.root.join("spec/fixtures/files/smime/#{email_address}.crt")
    end
    let(:certificate_string) do
      File.read(certificate_path)
    end

    context 'POST requests' do

      let(:parsed_certificate) { Certificate::X509::SMIME.new(certificate_string) }

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

        expect(json_response.first.keys).to match_array %w[
          id
          subject
          doc_hash
          fingerprint
          modulus
          not_before_at
          not_after_at
          raw
          private_key
          private_key_secret
          created_at
          updated_at
          subject_alternative_name
          usage
        ]
        expect(json_response.first['usage']).to match_array(%w[Signature Encryption])
        expect(json_response.first['subject_alternative_name']).to include(email_address)
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
        Rails.root.join("spec/fixtures/files/smime/#{email_address}.key")
      end

      let(:private_string) { File.read(private_path) }

      let(:secret) do
        Rails.root.join("spec/fixtures/files/smime/#{email_address}.secret").read.strip
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
      let(:group)                { create(:group, email_address: system_email_address) }

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
          expect(json_response['encryption']['success']).to be(false)
          expect(json_response['encryption']['comment']).to eq("The certificate for #{email_address} was not found.")
          expect(json_response['encryption']['commentPlaceholders']).to eq([])
          expect(json_response['encryption']['comment']).to include(email_address)
          expect(json_response['sign']['success']).to be(false)
          expect(json_response['sign']['comment']).to eq('The certificate for %s was not found.')
          expect(json_response['sign']['commentPlaceholders']).to eq([email_address])
        end
      end

      context 'certificate present' do

        before do
          create(:smime_certificate, :with_private, fixture: email_address)
        end

        it 'finds existing certificate' do
          post endpoint, params: search_query, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response['encryption']['success']).to be(true)
          expect(json_response['encryption']['comment']).to eq('The certificates for %s were found.')
          expect(json_response['encryption']['commentPlaceholders']).to eq([email_address])
          expect(json_response['sign']['success']).to be(true)
          expect(json_response['sign']['comment']).to eq('The certificate for %s was found.')
          expect(json_response['sign']['commentPlaceholders']).to eq([email_address])
        end

        context 'but expired' do
          let(:email_address) { 'expiredsmime1@example.com' }

          it 'finds existing certificate with comment' do
            post endpoint, params: search_query, as: :json

            expect(response).to have_http_status(:ok)
            expect(json_response['encryption']['success']).to be(false)
            expect(json_response['encryption']['comment']).to eq('There were certificates found for %s, but at least one of them is not valid yet or has expired.')
            expect(json_response['encryption']['commentPlaceholders']).to eq([email_address])
            expect(json_response['sign']['success']).to be(false)
            expect(json_response['sign']['comment']).to eq('The certificate for %s was found, but it is not valid yet or has expired.')
            expect(json_response['sign']['commentPlaceholders']).to eq([email_address])
          end
        end
      end
    end
  end
end

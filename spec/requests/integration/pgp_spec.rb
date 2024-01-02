# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Integration PGP', :aggregate_failures, authenticated_as: :user, type: :request do

  before do
    PGPKey.destroy_all
  end

  shared_examples 'check authentication handling' do
    context 'with agent user' do
      let(:user) { 'agent' }

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'request handling' do
    let(:user) { create(:admin) }

    context 'when calling GET / key_show' do
      let(:pgp_key)     { create(:'pgp_key/zammad@localhost') }
      let(:fingerprint) { pgp_key.fingerprint }

      before do
        get "/api/v1/integration/pgp/key/#{pgp_key.id}"
      end

      context 'with admin user' do
        it 'fetches key info' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to include(
            'fingerprint'     => pgp_key.fingerprint,
            'name'            => pgp_key.name,
            'email_addresses' => pgp_key.email_addresses,
            'expires_at'      => pgp_key.expires_at,
            'secret'          => false
          )
        end
      end

      include_examples 'check authentication handling'
    end

    context 'when calling GET / key_download' do
      let(:pgp_key)     { create(:'pgp_key/zammad@localhost') }
      let(:fingerprint) { pgp_key.fingerprint }
      let(:params)      { '' }

      before do
        get "/api/v1/integration/pgp/key_download/#{pgp_key.id}?#{params}"
      end

      context 'with a public key' do

        it 'downloads public key' do
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq(pgp_key.key)
        end

        context 'when requesting the private key' do
          let(:params) { 'secret=true' }

          it 'returns an error' do
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      context 'with a private key' do
        let(:pgp_key) { create(:'pgp_key/zammad@localhost', :with_private) }

        it 'downloads public key' do
          expect(response).to have_http_status(:ok)
          expect(response.body).to start_with('-----BEGIN PGP PUBLIC KEY BLOCK-----')
        end

        context 'when requesting the private key' do
          let(:params) { 'secret=true' }

          it 'downloads the private key' do
            expect(response).to have_http_status(:ok)
            expect(response.body).to eq(pgp_key.key)
          end
        end
      end

    end

    context 'when calling GET / key_list' do
      let(:pgp_key)     { create(:'pgp_key/zammad@localhost') }
      let(:fingerprint) { pgp_key.fingerprint }

      before do
        pgp_key
        get '/api/v1/integration/pgp/key'
      end

      context 'with admin user' do
        it 'fetches key infos' do
          expect(response).to have_http_status(:ok)
          expect(json_response.last).to include(
            'fingerprint'     => fingerprint,
            'name'            => pgp_key.name,
            'email_addresses' => pgp_key.email_addresses,
            'expires_at'      => pgp_key.expires_at,
            'secret'          => false
          )
        end
      end

      include_examples 'check authentication handling'
    end

    context 'when calling POST / create' do
      let(:public_key)         { Rails.root.join('spec/fixtures/files/pgp/zammad@localhost.pub.asc').read }
      let(:fingerprint)        { Rails.root.join('spec/fixtures/files/pgp/zammad@localhost.fingerprint').read }
      let(:private_key)        { Rails.root.join('spec/fixtures/files/pgp/zammad@localhost.asc').read }
      let(:private_passphrase) { Rails.root.join('spec/fixtures/files/pgp/zammad@localhost.passphrase').read }

      context 'with admin user' do
        context 'when importing a public key' do
          before do
            post '/api/v1/integration/pgp/key', params: { key: public_key }
          end

          it 'creates a new public key' do
            expect(response).to have_http_status(:created)
            expect(json_response).to include(
              'fingerprint'     => fingerprint,
              'name'            => 'zammad@localhost',
              'email_addresses' => ['zammad@localhost'],
              'expires_at'      => '2033-07-02T13:02:07.000Z',
              'secret'          => false
            )
            expect(PGPKey.last).to have_attributes(
              fingerprint:     fingerprint,
              name:            'zammad@localhost',
              email_addresses: ['zammad@localhost'],
              expires_at:      DateTime.parse('2033-07-02T13:02:07.000Z'),
              secret:          false
            )
            expect(PGPKey.count).to eq 1
          end

          context 'when public key has leading whitespace' do
            let(:public_key) { "   #{Rails.root.join('spec/fixtures/files/pgp/zammad@localhost.pub.asc').read}" }

            it 'creates a key if copy-pasted value has leading whitespace' do
              expect(response).to have_http_status(:created)
            end
          end

          context 'when adding the same key again' do
            before do
              post '/api/v1/integration/pgp/key', params: { key: public_key }
            end

            it 'returns an error' do
              expect(response).to have_http_status(:unprocessable_entity)
            end
          end

          context 'when importing a private key with the same fingerprint' do
            before do
              post '/api/v1/integration/pgp/key', params: { key: private_key, passphrase: private_passphrase }
            end

            it 'returns an error' do
              expect(response).to have_http_status(:unprocessable_entity)
            end
          end

          include_examples 'check authentication handling'
        end

        context 'when importing a private key' do
          before do
            post '/api/v1/integration/pgp/key', params: { key: private_key, passphrase: private_passphrase }
          end

          it 'creates only one key' do
            expect(response).to have_http_status(:created)
            expect(json_response).to include(
              'fingerprint'     => fingerprint,
              'name'            => 'zammad@localhost',
              'email_addresses' => ['zammad@localhost'],
              'expires_at'      => '2033-07-02T13:02:07.000Z',
              'secret'          => true
            )
            expect(PGPKey.last).to have_attributes(
              fingerprint:     fingerprint,
              name:            'zammad@localhost',
              email_addresses: ['zammad@localhost'],
              expires_at:      DateTime.parse('2033-07-02T13:02:07.000Z'),
              secret:          true
            )
            expect(PGPKey.count).to eq 1
          end
        end
      end
    end

    context 'when calling POST / search' do
      before do
        pgp_key
        post '/api/v1/integration/pgp', params: { ticket: ticket, article: article }
      end

      let(:email_address) { create(:email_address, email: 'zammad@localhost') }
      let(:group)         { create(:group, email_address: email_address) }
      let(:ticket)        { { 'group_id' => group.id } }
      let(:article)       { { 'to' => 'zammad@localhost', 'from' => 'zammad@localhost' } }

      context 'without keys present' do
        let(:pgp_key) { nil }

        it 'returns no possible security options' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq(
            {
              'encryption' => {
                'comment'             => 'The PGP key for %s was not found.',
                'commentPlaceholders' => ['zammad@localhost'],
                'success'             => false,
              },
              'sign'       => {
                'comment'             => 'The PGP key for %s was not found.',
                'commentPlaceholders' => ['zammad@localhost'],
                'success'             => false,
              },
              'type'       => 'PGP',
            }
          )
        end
      end

      context 'with keys present' do
        let(:pgp_key) { create(:pgp_key, :with_private, fixture: 'zammad@localhost') }

        it 'returns possible security options' do
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq(
            {
              'encryption' => {
                'comment'             => 'The PGP keys for %s were found.',
                'commentPlaceholders' => ['zammad@localhost'],
                'success'             => true,
              },
              'sign'       => {
                'comment'             => 'The PGP key for %s was found.',
                'commentPlaceholders' => ['zammad@localhost'],
                'success'             => true,
              },
              'type'       => 'PGP',
            }
          )
        end
      end
    end

    context 'when calling DELETE' do
      let(:pgp_key) { create(:'pgp_key/zammad@localhost') }

      before do
        delete "/api/v1/integration/pgp/key/#{pgp_key.id}"
      end

      context 'with admin user' do
        it 'deletes the key' do
          expect(response).to have_http_status(:ok)
        end
      end

      include_examples 'check authentication handling'
    end

    context 'when calling GET status' do
      it 'returns empty JSON if all is OK' do
        get '/api/v1/integration/pgp/status'

        expect(json_response).to be_blank
      end

      it 'returns error message if GnuPG is not up to date' do
        allow(SecureMailing::PGP).to receive(:required_version?).and_return(false)
        get '/api/v1/integration/pgp/status'

        expect(json_response).to include('error' => be_present)
      end
    end
  end
end

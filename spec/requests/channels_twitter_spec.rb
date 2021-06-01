# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Twitter channel API endpoints', type: :request do
  let!(:twitter_channel) { create(:twitter_channel) }
  let(:twitter_credential) { ExternalCredential.find(twitter_channel.options[:auth][:external_credential_id]) }

  let(:hash_signature) { %(sha256=#{Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', consumer_secret, payload))}) }
  let(:consumer_secret) { twitter_credential.credentials[:consumer_secret] }

  # What's this all about? See the "Challenge-Response Checks" section of this article:
  # https://developer.twitter.com/en/docs/accounts-and-users/subscribe-account-activity/guides/securing-webhooks
  describe 'GET /api/v1/channels_twitter_webhook' do
    let(:payload) { params[:crc_token] }
    let(:params) { { crc_token: 'foo' } }

    context 'with consumer secret and "crc_token" param' do
      it 'responds with { response_token: <hash_signature> }' do
        get '/api/v1/channels_twitter_webhook', params: params, as: :json

        expect(json_response).to eq('response_token' => hash_signature)
      end
    end

    context 'without valid twitter credentials in the DB' do
      before do
        twitter_credential.credentials.delete(:consumer_secret)
        twitter_credential.save!
      end

      it 'responds 422 Unprocessable Entity' do
        get '/api/v1/channels_twitter_webhook', params: params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without "crc_token" param' do
      before { params.delete(:crc_token) }

      it 'responds 422 Unprocessable Entity' do
        get '/api/v1/channels_twitter_webhook', params: params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /api/v1/channels_twitter_webhook' do
    let(:payload) { params.stringify_keys.to_s.gsub(%r{=>}, ':').delete(' ') }
    let(:headers) { { 'x-twitter-webhooks-signature': hash_signature } }
    let(:params) { { foo: 'bar', for_user_id: twitter_channel.options[:user][:id] } }

    # What's this all about? See the "Optional signature header validation" section of this article:
    # https://developer.twitter.com/en/docs/accounts-and-users/subscribe-account-activity/guides/securing-webhooks
    describe 'hash signature validation' do
      context 'with valid params and headers (i.e., not one of the failure cases below)' do
        it 'responds 200 OK' do
          post '/api/v1/channels_twitter_webhook', params: params, headers: headers, as: :json

          expect(response).to have_http_status(:ok)
        end
      end

      describe '"x-twitter-webhooks-signature" header' do
        context 'when absent' do
          let(:headers) { {} }

          it 'responds 422 Unprocessable Entity' do
            post '/api/v1/channels_twitter_webhook', params: params, headers: headers, as: :json

            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'when invalid (not based on consumer secret + payload)' do
          let(:headers) { { 'x-twitter-webhooks-signature': 'Not a valid signature' } }

          it 'responds 401 Not Authorized' do
            post '/api/v1/channels_twitter_webhook', params: params, headers: headers, as: :json

            expect(response).to have_http_status(:unauthorized)
          end
        end
      end

      describe '"for_user_id" param' do
        context 'when absent' do
          let(:params) { { foo: 'bar' } }

          it 'responds 422 Unprocessable Entity' do
            post '/api/v1/channels_twitter_webhook', params: params, headers: headers, as: :json

            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'without corresponding Channel' do
          let(:params) { { foo: 'bar', for_user_id: 'no_such_user' } }

          it 'responds 422 Unprocessable Entity' do
            post '/api/v1/channels_twitter_webhook', params: params, headers: headers, as: :json

            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end

    describe 'core behavior' do
      before do
        allow(TwitterSync).to receive(:new).and_return(twitter_sync)
        allow(twitter_sync).to receive(:process_webhook)
      end

      let(:twitter_sync) { instance_double('TwitterSync') }

      it 'delegates to TwitterSync#process_webhook' do
        post '/api/v1/channels_twitter_webhook', params: params, headers: headers, as: :json

        expect(twitter_sync).to have_received(:process_webhook).with(twitter_channel)
      end

      it 'responds with an empty hash' do
        post '/api/v1/channels_twitter_webhook', params: params, headers: headers, as: :json

        expect(json_response).to eq({})
      end
    end
  end
end

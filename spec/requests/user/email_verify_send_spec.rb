# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User endpoint', authenticated_as: false, type: :request do

  context 'when user resends verification email once' do
    it 'creates a token' do
      expect do
        post api_v1_users_email_verify_send_path, params: { email: create(:user).email }
      end.to change(Token, :count)
    end

    it 'returns success' do
      post api_v1_users_email_verify_send_path, params: { email: create(:user).email }
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when import_mode is on' do
    before { Setting.set('import_mode', true) }

    it 'returns failure' do
      post api_v1_users_email_verify_send_path, params: { email: create(:user).email }, as: :json
      expect(json_response).to include('error_human' => 'Could not send user verification email because import_mode setting is on.')
    end
  end

  # For the throttling, see config/initializers/rack_attack.rb.
  context 'when user resets password more than throttle allows', :rack_attack do

    let(:static_email) { create(:user).email }
    let(:static_ipv4)  { Faker::Internet.ip_v4_address }

    it 'blocks due to email throttling (multiple IPs)' do
      4.times do
        post api_v1_users_email_verify_send_path, params: { email: static_email }, headers: { 'X-Forwarded-For': Faker::Internet.ip_v4_address }
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'blocks due to source IP address throttling (multiple emails)' do
      4.times do
        # Ensure throttling even on modified path.
        post "#{api_v1_users_email_verify_send_path}.json", params: { email: create(:user).login }, headers: { 'X-Forwarded-For': static_ipv4 }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end

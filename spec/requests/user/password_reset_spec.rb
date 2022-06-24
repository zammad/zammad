# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User endpoint', type: :request, authenticated_as: false do

  context 'when user resets password once' do
    it 'creates a token' do
      expect do
        post api_v1_users_password_reset_path, params: { username: create(:user).login }
      end.to change(Token, :count)
    end

    it 'returns success' do
      post api_v1_users_password_reset_path, params: { username: create(:user).login }
      expect(response).to have_http_status(:ok)
    end
  end

  # For the throttling, see config/initializers/rack_attack.rb.
  context 'when user resets password more than throttle allows' do

    let(:static_username) { create(:user).login }
    let(:static_ipv4)     { Faker::Internet.ip_v4_address }

    it 'blocks due to username throttling (multiple IPs)' do
      # Throttle should happen after 5 requests, but that is not reliable enough due to CI slowness.
      15.times do
        post api_v1_users_password_reset_path, params: { username: static_username }, headers: { 'X-Forwarded-For': Faker::Internet.ip_v4_address }
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'blocks due to source IP address throttling (multiple usernames)' do
      15.times do
        # Ensure throttling even on modified path.
        post "#{api_v1_users_password_reset_path}.json", params: { username: create(:user).login }, headers: { 'X-Forwarded-For': static_ipv4 }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end

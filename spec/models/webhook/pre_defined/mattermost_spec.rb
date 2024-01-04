# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Webhook > Mattermost', integration: true, performs_jobs: true, required_envs: %w[MATTERMOST_URL MATTERMOST_USER MATTERMOST_PASSWORD MATTERMOST_CHANNEL], time_zone: 'Europe/London' do # rubocop:disable RSpec/DescribeClass
  # Shared/persistent variables
  mattermost_hook_initialized = false
  mattermost_access_token     = ''
  mattermost_zammad_channel   = nil
  zammad_webhook              = nil

  let(:zammad_base_url)            { "#{Capybara.app_host}:#{Capybara.current_session.server.port}" }
  let(:mattermost_url)             { ENV['MATTERMOST_URL'] }
  let(:mattermost_api_url)         { "#{mattermost_url}/api/v4" }
  let(:mattermost_auth_header)     { { Authorization: "Bearer #{mattermost_access_token}" } }
  let(:mattermost_default_headers) { { headers: mattermost_auth_header, json: true } }

  let(:mattermost_endpoints) do
    {
      auth:           "#{mattermost_api_url}/users/login",
      channel_list:   "#{mattermost_api_url}/channels",
      incoming_hooks: "#{mattermost_api_url}/hooks/incoming",
      hooks:          "#{mattermost_url}/hooks",
    }
  end

  let(:mattermost_payloads) do
    {
      auth:           { login_id: ENV['MATTERMOST_USER'], password: ENV['MATTERMOST_PASSWORD'] },
      incoming_hooks: { display_name: 'Zammad', description: 'Incoming webhook for Zammad' },
    }
  end

  before do
    next if mattermost_hook_initialized

    # Get auth token.
    auth_response = UserAgent.post(mattermost_endpoints[:auth], mattermost_payloads[:auth], { json: true })

    raise 'Authentication failed' if !auth_response.success?

    mattermost_access_token = auth_response.header['token']
    raise 'No access_token found' if mattermost_access_token.blank?

    # Get channel id.
    channel_response = UserAgent.get(mattermost_endpoints[:channel_list], {}, mattermost_default_headers)
    raise 'No channel found' if !channel_response.success? || channel_response.data.blank?

    mattermost_zammad_channel = channel_response.data.find { |channel| channel['name'].eql?(ENV['MATTERMOST_CHANNEL']) }
    raise 'No channel found' if mattermost_zammad_channel.nil?

    # Create incoming webhook.
    incoming_webhook_response = UserAgent.post(mattermost_endpoints[:incoming_hooks], mattermost_payloads[:incoming_hooks].merge(channel_id: mattermost_zammad_channel['id']), mattermost_default_headers)
    raise 'No incoming webhook found' if !incoming_webhook_response.success?

    webhook_id = incoming_webhook_response.data['id']
    raise 'No incoming webhook found' if webhook_id.blank?

    zammad_webhook = create(
      :mattermost_webhook,
      endpoint:    "#{mattermost_endpoints[:hooks]}/#{webhook_id}",
      preferences: {
        pre_defined_webhook: {
          messaging_username: Faker::Internet.unique.username,
          messaging_channel:  mattermost_zammad_channel['name'],
          messaging_icon_url: Faker::Internet.unique.url,
        },
      }
    )

    mattermost_hook_initialized = true
  end

  context 'when a trigger for ticket create is used' do
    let(:condition) { { 'ticket.action' => { 'operator' => 'is', 'value' => 'create' } } }
    let(:perform)   { { 'notification.webhook' => { 'webhook_id' => zammad_webhook.id.to_s } } }
    let(:trigger)   { create(:trigger, activator: 'action', condition: condition, perform: perform) }
    let(:message)   { "Test for Mattermost (#{SecureRandom.uuid})" }

    before do
      trigger
    end

    it 'creates a post in the related Mattermost channel', :aggregate_failures do
      create(:ticket, group: Group.first, title: message)
      perform_enqueued_jobs commit_transaction: true

      posts_response = UserAgent.get(
        "#{mattermost_api_url}/channels/#{mattermost_zammad_channel['id']}/posts",
        {},
        mattermost_default_headers
      )

      last_post_id = posts_response.data['order'].first

      expect(last_post_id).not_to be_nil
      expect(posts_response.data.dig('posts', last_post_id, 'message')).to eq("# #{message}")
    end
  end
end

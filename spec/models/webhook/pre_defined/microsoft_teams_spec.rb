# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Webhook > MS Teams', integration: true, performs_jobs: true, required_envs: %w[MS_TEAMS_CI_WEBHOOK_URL], retry: 5, retry_wait: 30.seconds, use_vcr: true do # rubocop:disable RSpec/DescribeClass
  let(:webhook)   { create(:ms_teams_webhook, endpoint: ENV['MS_TEAMS_CI_WEBHOOK_URL']) }
  let(:perform)   { { 'notification.webhook' => { 'webhook_id' => webhook.id.to_s } } }
  let(:trigger)   { create(:trigger, activator: 'action', condition: condition, perform: perform) }

  # At first glance, we tried to use the MS Graph API to delete all messages in the channel.
  # After some research, we found out, that it is quite hard to accomplish this
  #   due to protected access to the required API endpoints.

  # Following code could be used to get an access token for the MS Graph API:
  #
  # token_response = UserAgent.post(
  #   "https://login.microsoftonline.com/<tenant id>/oauth2/v2.0/token",
  #   {
  #     client_id:     'xxx',
  #     client_secret: 'xxx',
  #     scope:         'https://graph.microsoft.com/.default ',
  #     grant_type:    'client_credentials',
  #   }
  # )
  # token_data = JSON.parse(token_response.body)
  # @token = token_data['access_token']

  context 'with ticket create as condition' do
    let(:condition) { { 'ticket.action' => { 'operator' => 'is', 'value' => 'create' } } }
    let(:message) { 'MS Teams Webhook Test' }

    before do
      trigger
    end

    it 'creates a message in the MS Teams channel', :aggregate_failures do
      create(:ticket, group: Group.first, title: message)
      perform_enqueued_jobs commit_transaction: true

      expect(HttpLog.last).to have_attributes(
        direction: 'out',
        facility:  'webhook',
        method:    'POST',
        url:       ENV['MS_TEAMS_CI_WEBHOOK_URL'],
        status:    202.to_s,
      )
    end
  end
end

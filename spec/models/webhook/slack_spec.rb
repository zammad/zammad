# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'slack-ruby-client' # Only load this gem when it is really used.

CHANNEL_NAME = ENV['SLACK_CI_CHANNEL_NAME']
OAUTH_TOKEN = ENV['SLACK_CI_OAUTH_TOKEN']
WEBHOOK_URL = ENV['SLACK_CI_WEBHOOK_URL']

RSpec.describe 'Webhook > Slack', integration: true, performs_jobs: true, required_envs: %w[SLACK_CI_CHANNEL_NAME SLACK_CI_OAUTH_TOKEN SLACK_CI_WEBHOOK_URL], time_zone: 'Europe/London', use_vcr: true do # rubocop:disable RSpec/DescribeClass
  let(:webhook) { create(:webhook, endpoint: WEBHOOK_URL, custom_payload: custom_payload) }
  let(:perform) { { 'notification.webhook' => { 'webhook_id' => webhook.id.to_s } } }

  let(:custom_payload) do
    {
      channel:     CHANNEL_NAME,
      username:    'zammad_agent',
      icon_url:    'https://zammad.com/assets/images/logo-200x200.png',
      mrkdwn:      true,
      text:        '# #{ticket.title}', # rubocop:disable Lint/InterpolationCheck
      attachments: [
        {
          text:      '"_[Ticket##{ticket.number}](#{notification.link}): #{notification.message}_\n\n#{notification.changes}\n\n#{notification.body}"', # rubocop:disable Lint/InterpolationCheck
          mrkdwn_in: [
            'text',
          ],
          color:     '#{ticket.current_state_color}', # rubocop:disable Lint/InterpolationCheck
        },
      ],
    }.to_json
  end

  before :all do # rubocop:disable RSpec/BeforeAfterAll
    delete_all_test_chat_messages if live_mode?
  end

  context 'with ticket create as condition' do
    let(:trigger)   { create(:trigger, condition: condition, perform: perform) }
    let(:condition) { { 'ticket.action' => { 'operator' => 'is', 'value' => 'create' } } }
    let(:message)   { 'Slack Webhook Test' }

    before do
      trigger
    end

    it 'creates a message in the slack channel' do
      create(:ticket, group: Group.first, title: message)
      perform_enqueued_jobs commit_transaction: true

      expect(message).to have_message_count(1)
    end
  end

  context 'with ticket update as condition' do
    let(:trigger)        { create(:trigger, condition: condition, perform: perform) }
    let(:condition)      { { 'ticket.action' => { 'operator' => 'is', 'value' => 'update' } } }
    let(:message)        { 'Another Slack Webhook Test' }
    let(:update_message) { 'New article' }
    let(:ticket)         { create(:ticket, group: Group.first, title: message) }

    before do
      trigger
      ticket
      perform_enqueued_jobs commit_transaction: true
    end

    it 'creates a message in the slack channel' do
      ticket.update!(title: update_message)
      create(:ticket_article, ticket_id: ticket.id)
      perform_enqueued_jobs commit_transaction: true

      expect(update_message).to have_message_count(1)
    end
  end
end

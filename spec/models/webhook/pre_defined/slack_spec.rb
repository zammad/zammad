# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'slack-ruby-client' # Only load this gem when it is really used.

RSpec.describe 'Webhook > Slack', integration: true, performs_jobs: true, required_envs: %w[SLACK_CI_CHANNEL_NAME SLACK_CI_OAUTH_TOKEN SLACK_CI_WEBHOOK_URL], time_zone: 'Europe/London', use_vcr: true do # rubocop:disable RSpec/DescribeClass
  let(:webhook)   { create(:slack_webhook, endpoint: ENV['SLACK_CI_WEBHOOK_URL']) }
  let(:perform)   { { 'notification.webhook' => { 'webhook_id' => webhook.id.to_s } } }
  let(:activator) { 'action' }
  let(:trigger)   { create(:trigger, activator: activator, condition: condition, perform: perform) }

  before :all do # rubocop:disable RSpec/BeforeAfterAll
    delete_all_test_chat_messages if live_mode?
  end

  context 'with ticket create as condition' do
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

  context 'with ticket reminder reached as condition' do
    let(:condition) { { 'ticket.group_id' => { 'operator' => 'is', 'value' => [Group.first.id] } } }
    let(:message)   { 'Reminder reached!' }
    let(:activator) { 'time' }
    let(:ticket)    do
      create(
        :ticket,
        group:        Group.first,
        title:        'Slack Webhook Test (Reminder reached)',
        state:        Ticket::State.find_by(name: 'pending reminder'),
        pending_time: Time.zone.local(2023, 2, 7, 12)
      )
    end

    before do
      trigger
      ticket
      Ticket.process_pending
      perform_enqueued_jobs commit_transaction: true
    end

    it 'creates a message in the slack channel' do
      expect(message).to have_message_count(1)
    end
  end
end

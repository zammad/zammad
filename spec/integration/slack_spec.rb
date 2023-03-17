# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'slack-ruby-client' # Only load this gem when it is really used.

CHANNEL_NAME = ENV['SLACK_CI_CHANNEL_NAME']
OAUTH_TOKEN = ENV['SLACK_CI_OAUTH_TOKEN']
WEBHOOK_URL = ENV['SLACK_CI_WEBHOOK_URL']

RSpec.describe 'Slack Integration', integration: true, performs_jobs: true, required_envs: %w[SLACK_CI_CHANNEL_NAME SLACK_CI_OAUTH_TOKEN SLACK_CI_WEBHOOK_URL], time_zone: 'Europe/London', use_vcr: true do # rubocop:disable RSpec/DescribeClass
  let(:slack_group)  { create(:group) }
  let(:types)        { %w[create update reminder_reached] }
  let(:items) do
    [
      {
        group_ids: [slack_group.id],
        types:     types,
        webhook:   WEBHOOK_URL,
        channel:   CHANNEL_NAME,
        username:  'zammad_agent',
        expand:    false,
      }
    ]
  end
  let(:group) { slack_group }
  let(:customer)   { create(:customer) }
  let(:state_name) { 'new' }
  let(:ticket)     { create(:ticket, customer: customer, group: group, title: message, state_name: state_name) }
  let(:article)    { create(:ticket_article, :outbound_note, ticket: ticket, body: message, sender_name: 'Customer', from: customer.fullname) }

  before :all do # rubocop:disable RSpec/BeforeAfterAll
    delete_all_test_chat_messages if live_mode?
  end

  before do
    Setting.set('slack_integration', true)
    Setting.set('slack_config', { items: items })

    ticket && article

    perform_enqueued_jobs commit_transaction: true
  end

  context 'with default group' do
    let(:message) { 'foo' }
    let(:group) { Group.first }

    it 'publishes no ticket updates', :aggregate_failures do
      expect(message).to have_message_count(0)

      ticket.update!(state: Ticket::State.find_by(name: 'open'))

      perform_enqueued_jobs commit_transaction: true

      expect(message).to have_message_count(0)
    end

    context 'with create event only' do
      let(:types) { 'create' }
      let(:message) { 'bar' }

      it 'publishes no ticket updates', :aggregate_failures do
        expect(message).to have_message_count(0)

        ticket.update!(state: Ticket::State.find_by(name: 'open'))

        perform_enqueued_jobs commit_transaction: true

        expect(message).to have_message_count(0)
      end
    end
  end

  context 'with slack group' do
    let(:message) { 'baz' }

    it 'publishes ticket updates', :aggregate_failures do
      expect(message).to have_message_count(1)

      new_message = 'qux'

      ticket.update!(title: new_message)

      perform_enqueued_jobs commit_transaction: true

      expect(new_message).to have_message_count(1)

      ticket.update!(state: Ticket::State.find_by(name: 'pending reminder'), pending_time: Time.zone.local(2023, 2, 7, 12))

      perform_enqueued_jobs commit_transaction: true

      expect(new_message).to have_message_count(2)

      Ticket.process_pending
      perform_enqueued_jobs commit_transaction: true

      expect(new_message).to have_message_count(3)

      Ticket.process_pending
      perform_enqueued_jobs commit_transaction: true

      expect(new_message).to have_message_count(3)
    end

    context 'with create event only' do
      let(:types)   { 'create' }
      let(:message) { 'corge' }

      it 'publishes no ticket updates', :aggregate_failures do
        expect(message).to have_message_count(1)

        new_message = 'grault'

        ticket.update!(title: new_message)

        perform_enqueued_jobs commit_transaction: true

        expect(new_message).to have_message_count(0)
      end
    end
  end

  def live_mode?
    %w[1 true].include?(ENV['CI_IGNORE_CASSETTES'])
  end

  def delete_all_test_chat_messages
    client = slack_client
    channel_id = slack_channel_id(client)
    channel_history = slack_channel_history(client, channel_id)

    message_count = 0

    channel_history['messages'].each do |message|
      next if message['subtype'] != 'bot_message'
      next if !message['ts']

      client.chat_delete channel: channel_id, ts: message['ts'], as_user: true
      message_count += 1
    end

    Rails.logger.debug { "Deleted #{message_count} existing bot message(s)..." } if message_count > 0
  end

  def slack_client
    Slack.configure do |config|
      config.token = OAUTH_TOKEN
    end

    client = Slack::Web::Client.new
    client.auth_test

    client
  end

  def slack_channel_id(client)
    channels = client.conversations_list['channels']
    channel_id = nil
    channels.each do |channel|
      next if channel['name'] != CHANNEL_NAME

      channel_id = channel['id']
    end

    if !channel_id
      raise "ERROR: No such channel '#{CHANNEL_NAME}'"
    end

    channel_id
  end

  def slack_channel_history(client, channel_id)
    channel_history = client.conversations_history(channel: channel_id)

    if !channel_history
      raise "ERROR: No history for channel #{CHANNEL_NAME}/#{channel_id}"
    end

    if !channel_history['messages']
      raise "ERROR: No history messages for channel #{CHANNEL_NAME}/#{channel_id}"
    end

    channel_history
  end

  define :have_message_count do
    match do
      check_message_count
    end

    def check_message_count
      client = slack_client
      channel_id = slack_channel_id(client)
      channel_history = slack_channel_history(client, channel_id)
      message_count = get_message_count(channel_history)

      expect(message_count).to eq(expected)
    end

    def get_message_count(channel_history)
      message_count = 0

      channel_history['messages'].each do |message|
        next if !message['text']

        if message['text'].include?(actual)
          message_count += 1
        end
      end

      message_count
    end
  end
end

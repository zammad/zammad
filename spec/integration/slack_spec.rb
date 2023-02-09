# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'slack-ruby-client' # Only load this gem when it is really used.

RSpec.describe 'Slack Integration', integration: true, performs_jobs: true, required_envs: %w[SLACK_CI_CHANNEL SLACK_CI_WEBHOOK SLACK_CI_CHECKER_TOKEN], time_zone: 'Europe/London', use_vcr: true do # rubocop:disable RSpec/DescribeClass
  let(:channel_name) { ENV['SLACK_CI_CHANNEL'] }
  let(:slack_group)  { create(:group) }
  let(:types)        { %w[create update reminder_reached] }
  let(:items) do
    [
      {
        group_ids: [slack_group.id],
        types:     types,
        webhook:   ENV['SLACK_CI_WEBHOOK'],
        channel:   channel_name,
        username:  'zammad bot',
        expand:    false,
      }
    ]
  end
  let(:group) { slack_group }
  let(:customer)   { create(:customer) }
  let(:state_name) { 'new' }
  let(:ticket)     { create(:ticket, customer: customer, group: group, title: message, state_name: state_name) }
  let(:article)    { create(:ticket_article, :outbound_note, ticket: ticket, body: message, sender_name: 'Customer', from: customer.fullname) }

  before do
    Setting.set('slack_integration', true)
    Setting.set('slack_config', { items: items })

    ticket && article

    perform_enqueued_jobs commit_transaction: true
  end

  context 'with default group' do
    let(:message) { generate_message('dog... 6081e055b777510463bf') }
    let(:group) { Group.first }

    it 'publishes no ticket updates', :aggregate_failures do
      expect(message).to have_message_count(0)

      ticket.update!(state: Ticket::State.find_by(name: 'open'))

      perform_enqueued_jobs commit_transaction: true

      expect(message).to have_message_count(0)
    end

    context 'with create event only' do
      let(:types) { 'create' }
      let(:message) { generate_message('home... ce2601a9924d302fc6ad') }

      it 'publishes no ticket updates', :aggregate_failures do
        expect(message).to have_message_count(0)

        ticket.update!(state: Ticket::State.find_by(name: 'open'))

        perform_enqueued_jobs commit_transaction: true

        expect(message).to have_message_count(0)
      end
    end
  end

  context 'with slack group' do
    let(:message) { generate_message('cat... 53d106ed8a69abcff434') }

    it 'publishes ticket updates', :aggregate_failures do
      expect(message).to have_message_count(1)

      new_message = generate_message('house... 09d0e102bdade3968ef8')

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
      let(:message) { generate_message('yesterday... 6afc704a41534c69755b') }

      it 'publishes no ticket updates', :aggregate_failures do
        expect(message).to have_message_count(1)

        new_message = generate_message('tomorrow... 1a411280022ea922703a')

        ticket.update!(title: new_message)

        perform_enqueued_jobs commit_transaction: true

        expect(new_message).to have_message_count(0)
      end
    end
  end

  def live_mode?
    %w[1 true].include?(ENV['CI_IGNORE_CASSETTES'])
  end

  def generate_message(default_message)
    return random_message if live_mode?

    default_message
  end

  def random_message
    "#{rand_word}... #{hash_gen}"
  end

  def hash_gen
    SecureRandom.hex(10)
  end

  def rand_word
    words = [
      'dog',
      'cat',
      'house',
      'home',
      'yesterday',
      'tomorrow',
      'new york',
      'berlin',
      'coffee script',
      'java script',
      'bob smith',
      'be open',
      'really nice',
      'stay tuned',
      'be a good boy',
      'invent new things',
    ]

    words.sample
  end

  define :have_message_count do
    match do
      check_message_count
    end

    def check_message_count
      channel_history = fetch_channel_history
      message_count = get_message_count(channel_history)

      expect(message_count).to eq(expected)
    end

    def fetch_channel_history
      Slack.configure do |config|
        config.token = ENV['SLACK_CI_CHECKER_TOKEN']
      end

      client = Slack::Web::Client.new
      client.auth_test

      channels = client.conversations_list['channels']
      channel_id = nil
      channels.each do |channel|
        next if channel['name'] != channel_name

        channel_id = channel['id']
      end

      if !channel_id
        raise "ERROR: No such channel '#{channel_name}'"
      end

      channel_history = client.conversations_history(channel: channel_id)

      if !channel_history
        raise "ERROR: No history for channel #{channel_name}/#{channel_id}"
      end

      if !channel_history['messages']
        raise "ERROR: No history messages for channel #{channel_name}/#{channel_id}"
      end

      channel_history
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

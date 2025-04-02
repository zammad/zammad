# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module RSpecSlackHelper
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

    Rails.logger.debug { "Deleted #{message_count} existing bot message(s)..." } if message_count.positive?
  end

  def slack_client
    Slack.configure do |config|
      config.token = ENV['SLACK_CI_OAUTH_TOKEN']
    end

    client = Slack::Web::Client.new
    client.auth_test

    client
  end

  def slack_channel_id(client)
    channels = client.conversations_list['channels']
    channel_id = nil
    channels.each do |channel|
      next if channel['name'] != ENV['SLACK_CI_CHANNEL_NAME']

      channel_id = channel['id']
    end

    if !channel_id
      raise "ERROR: No such channel '#{ENV['SLACK_CI_CHANNEL_NAME']}'"
    end

    channel_id
  end

  def slack_channel_history(client, channel_id)
    channel_history = client.conversations_history(channel: channel_id)

    if !channel_history
      raise "ERROR: No history for channel #{ENV['SLACK_CI_CHANNEL_NAME']}/#{channel_id}"
    end

    if !channel_history['messages']
      raise "ERROR: No history messages for channel #{ENV['SLACK_CI_CHANNEL_NAME']}/#{channel_id}"
    end

    channel_history
  end

  RSpec::Matchers.define :have_message_count do
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
        next if !message['text'] && message['attachments'].blank?

        if message['text']&.include?(actual) || message['attachments'].try(:first)['text'].include?(actual)
          message_count += 1
        end
      end

      message_count
    end
  end

  def live_mode?
    %w[1 true].include?(ENV['CI_IGNORE_CASSETTES'])
  end
end

RSpec.configure do |config|
  config.include RSpecSlackHelper
end

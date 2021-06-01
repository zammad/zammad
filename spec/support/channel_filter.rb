# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ChannelFilterHelper

  # Provides a helper method to run the current class Channel::Filter.
  # Make sure to define type: :channel_filter in your RSpec.describe call.
  #
  # @param [Hash] mail_hash contains the parsed mail data
  # @param [Channel] channel contains the channel that processes this call which is usually not needed
  #
  # @example
  #  filter({:'x-zammad-ticket-id' => 1234, ...})
  #
  # @return [nil]
  def filter(mail_hash, channel: {}, transaction_params: {})
    described_class.run(channel, mail_hash, transaction_params)
  end

  # Provides a helper method to parse a mail String and run the current class Channel::Filter.
  # Make sure to define type: :channel_filter in your RSpec.describe call.
  #
  # @param [String] mail_string contains the plain mail content
  # @param [Channel] channel contains the channel that processes this call which is usually not needed
  #
  # @example
  #  filter_parsed('From: me@example.com...')
  #
  # @return [Hash] parsed mails Hash
  def filter_parsed(mail_string, channel: {})
    Channel::EmailParser.new.parse(mail_string).tap do |mail_hash|
      filter(mail_hash, channel: channel)
    end
  end
end

RSpec.configure do |config|
  config.include ChannelFilterHelper, type: :channel_filter
end

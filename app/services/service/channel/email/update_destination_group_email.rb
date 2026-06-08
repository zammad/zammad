# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Channel::Email::UpdateDestinationGroupEmail < Service::Base
  attr_reader :group, :channel, :email_address

  def initialize(group:, channel:, email_address: nil)
    @channel = channel
    @group = group
    @email_address = email_address || EmailAddress.find_by(channel_id: channel.id)
  end

  def execute
    return if email_address.nil?

    group.update!(email_address: email_address)
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::MicrosoftGraphOutbound < Channel::Driver::BaseEmailOutbound

  def deliver(options, attr, notification = false) # rubocop:disable Style/OptionalBooleanParameter

    # return if we run import mode
    return if Setting.get('import_mode')

    attr = prepare_message_attrs(attr)

    deliver_mail(attr, notification, MicrosoftGraphOutboundClient, options)
  end

  class MicrosoftGraphOutboundClient
    def initialize(values)
      @settings = values
    end

    def deliver!(mail)
      access_token = @settings[:password]
      mailbox      = @settings[:shared_mailbox].presence || @settings[:user]

      MicrosoftGraph
        .new(access_token:, mailbox:)
        .send_message(mail)
    end
  end
end

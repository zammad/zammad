# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::Whatsapp
  def deliver(options, attr, _notification = false)
    return true if Setting.get('import_mode')

    message = "Whatsapp::Outgoing::Message::#{attr[:message_type].capitalize}".constantize.new(
      access_token:     options[:access_token],
      phone_number_id:  options[:phone_number_id],
      recipient_number: attr[:recipient_number]
    )

    if attr[:message_type] == 'text'
      return message.deliver(
        body: attr[:body]
      )
    end

    message.deliver(
      caption: attr[:body],
      store:   attr[:attachment]
    )
  end
end

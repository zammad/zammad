# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module PushMessages

  def self.enabled?
    return true if Thread.current[:push_messages].instance_of?(Array)

    false
  end

  def self.init
    return true if enabled?

    Thread.current[:push_messages] = []
  end

  def self.send(data) # rubocop:disable Zammad/ForbidDefSend
    if !PushMessages.enabled?
      Sessions.broadcast(
        data[:message],
        data[:type],
        data[:current_user_id],
      )
      return true
    end
    message = { type: 'broadcast', data: data }
    Thread.current[:push_messages].push message
  end

  def self.send_to(user_id, data)
    if !PushMessages.enabled?
      Sessions.send_to(user_id, data)
      return true
    end
    message = { type: 'send_to', user_id: user_id, data: data }
    Thread.current[:push_messages].push message
  end

  def self.finish
    deliver(flush)
  end

  # Captures and clears the buffered messages, without sending them yet.
  #   Used to detach delivery from the buffer's lifecycle, e.g. to defer sending
  #   until after a transaction commits while still always clearing the buffer,
  #   regardless of whether that transaction ends up committing or rolling back.
  def self.flush
    return [] if !enabled?

    messages = Thread.current[:push_messages]
    Thread.current[:push_messages] = nil
    messages
  end

  def self.deliver(messages)
    messages.each do |message|
      if message[:type] == 'send_to'
        Sessions.send_to(message[:user_id], message[:data])
      else
        Sessions.broadcast(
          message[:data][:message],
          message[:data][:type],
          message[:data][:current_user_id],
        )
      end
    end
    true
  end

end

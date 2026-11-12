# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The new UI's counterpart of the legacy chat_session_message event, stricter in that only the agent
#   who runs the session can write to it.
class Service::Chat::Session::MessageAdd < Service::Base
  requires_current_user!

  attr_reader :session, :content

  def initialize(session:, content:)
    @session = session
    @content = content
  end

  def execute
    raise Exceptions::UnprocessableContent, __('The message must not be empty.') if content.blank?

    # The check holds only under the lock, as for ending and transferring: another request can take the
    #   session away or close it between its load and the write.
    message = session.with_lock do
      raise Exceptions::Forbidden, __('You are not running this chat session.') if !session.running_for?(current_user)

      ::Chat::Message.create!(chat_session_id: session.id, content: content, created_by_id: current_user.id)
    end

    # The subscription of the agent loads the message from the database, so inside a transaction, e.g. the
    #   lock of the greeting job, it is sent once that is committed. No client to leave out: the agent has no
    #   legacy client id.
    ApplicationModel.current_transaction.after_commit do
      session.send_to_recipients(
        event: 'chat_session_message',
        data:  {
          session_id: session.session_id,
          message:    message,
        },
      )
    end

    message
  end
end

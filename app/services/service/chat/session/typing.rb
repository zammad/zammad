# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The new UI's counterpart of the legacy chat_session_typing event. Nothing is stored.
class Service::Chat::Session::Typing < Service::Base
  requires_current_user!

  attr_reader :session

  def initialize(session:)
    @session = session
  end

  def execute
    raise Exceptions::Forbidden, __('You are not running this chat session.') if !session.running_for?(current_user)

    session.send_to_recipients(
      event: 'chat_session_typing',
      data:  {
        session_id: session.session_id,
        user_id:    current_user.id,
      },
    )

    true
  end
end

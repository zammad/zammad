# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::ChatSessionLeaveTemporary < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session

    ChatLeaveJob.set(wait: 0.5.minutes).perform_later(chat_session.id, @client_id, @session)

    false
  end

end

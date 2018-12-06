class Sessions::Event::ChatSessionLeaveTemporary < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session

    Delayed::Job.enqueue(
      Observer::Chat::Leave::BackgroundJob.new(chat_session.id, @client_id, @session),
      {
        run_at: Time.zone.now + 0.5.minutes
      }
    )

    false
  end

end

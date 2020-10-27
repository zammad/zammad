class Observer::Chat::Leave::BackgroundJob
  def initialize(chat_session_id, client_id, session)
    @chat_session_id = chat_session_id
    @client_id = client_id
    @session = session
  end

  def perform
    if Gem::Version.new(Version.get) >= Gem::Version.new('4.0.x')
      ActiveSupport::Deprecation.warn("This file has been migrated to the ActiveJob 'ChatLeaveJob' and is therefore deprecated and should get removed.")
    end

    ChatLeaveJob.perform_now(@chat_session_id, @client_id, @session)
  end
end

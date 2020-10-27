class Observer::Ticket::Article::CommunicateTelegram::BackgroundJob
  def initialize(id)
    @article_id = id
  end

  def perform
    if Gem::Version.new(Version.get) >= Gem::Version.new('4.0.x')
      ActiveSupport::Deprecation.warn("This file has been migrated to the ActiveJob 'CommunicateTelegramJob' and is therefore deprecated and should get removed.")
    end

    CommunicateTelegramJob.perform_now(@article_id)
  end
end

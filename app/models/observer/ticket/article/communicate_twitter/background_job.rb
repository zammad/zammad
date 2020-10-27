class Observer::Ticket::Article::CommunicateTwitter::BackgroundJob
  def initialize(id)
    @article_id = id
  end

  def perform
    if Gem::Version.new(Version.get) >= Gem::Version.new('4.0.x')
      ActiveSupport::Deprecation.warn("This file has been migrated to the ActiveJob 'CommunicateTwitterJob' and is therefore deprecated and should get removed.")
    end

    CommunicateTwitterJob.perform_now(@article_id)
  end
end

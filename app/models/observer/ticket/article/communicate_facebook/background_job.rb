class Observer::Ticket::Article::CommunicateFacebook::BackgroundJob
  def initialize(id)
    @article_id = id
  end

  def perform
    if Gem::Version.new(Version.get) >= Gem::Version.new('4.0.x')
      ActiveSupport::Deprecation.warn("This file has been migrated to the ActiveJob 'CommunicateFacebookJob' and is therefore deprecated and should get removed.")
    end

    CommunicateFacebookJob.perform_now(@article_id)
  end
end

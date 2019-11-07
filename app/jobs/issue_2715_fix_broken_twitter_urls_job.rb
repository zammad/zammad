class Issue2715FixBrokenTwitterUrlsJob < ApplicationJob
  def perform
    Ticket::Article.joins(:type)
                   .where(ticket_article_types: { name: 'twitter direct-message' })
                   .order(created_at: :desc)
                   .limit(10_000)
                   .find_each do |dm|
      dm.preferences[:links]&.each do |link|
        link[:url] = "https://twitter.com/messages/#{dm.preferences[:twitter][:recipient_id]}-#{dm.preferences[:twitter][:sender_id]}"
      end

      dm.save!
    end
  end
end

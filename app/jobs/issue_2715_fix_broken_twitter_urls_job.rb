# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2715FixBrokenTwitterUrlsJob < ApplicationJob
  STATUS_TEMPLATE = 'https://twitter.com/_/status/%<message_id>s'.freeze
  DM_TEMPLATE = 'https://twitter.com/messages/%<recipient_id>s-%<sender_id>s'.freeze

  def perform
    Ticket::Article.joins(:type)
                   .where(ticket_article_types: { name: ['twitter status', 'twitter direct-message'] })
                   .order(created_at: :desc)
                   .limit(10_000)
                   .find_each { |article| fix_broken_links(article) }
  end

  private

  def fix_broken_links(article)
    type = Ticket::Article::Type.lookup(id: article.type_id).name

    article.preferences[:links]&.each do |link|
      link[:url] = case type
                   when 'twitter status'
                     STATUS_TEMPLATE % article.attributes.symbolize_keys
                   when 'twitter direct-message'
                     DM_TEMPLATE % article.preferences[:twitter].symbolize_keys
                   end
    end

    article.save!
  end
end

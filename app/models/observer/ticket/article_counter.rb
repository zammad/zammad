class Observer::Ticket::ArticleCounter < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # get article count
    record.ticket.article_count = record.ticket.articles.count

    # save ticket
    record.ticket.save
  end
end
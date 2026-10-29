# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Ticket::PopoverController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def show
    authorize!(ticket, :agent_read_access?)

    render json: {
      summary:       summary,
      first_article: article_payload(first_article),
      last_article:  article_payload(last_article),
      checklist:     checklist,
      assets:        assets,
    }
  end

  private

  def ticket
    @ticket ||= Ticket.find(params[:id])
  end

  # The same article set the summary reads: internal notes included, because
  #   this endpoint is only available to agents.
  def articles
    ticket.articles.without_system_notifications
  end

  def first_article
    @first_article ||= articles.first
  end

  def last_article
    @last_article ||= articles.last
  end

  # Deliberately without the analytics block of Ticket::SummarizeController, so
  #   that a hover neither enqueues a generation nor marks the summary as seen.
  def summary
    content = Service::Ticket::AIAssistance::StoredSummary
      .with_current_user(current_user)
      .execute(ticket:)

    return if content.blank?

    content.slice('customer_request', 'customer_emotion', 'customer_mood').compact_blank.presence
  end

  def article_payload(article)
    return if article.blank?

    {
      id:           article.id,
      body_excerpt: article.body_excerpt,
      author:       { id: article.author_id },
      sender:       article.sender&.name,
      internal:     article.internal,
    }
  end

  # The avatars of the rendered articles need their authors as records.
  def assets
    [first_article, last_article].compact.map(&:author).uniq.reduce({}) do |memo, author|
      author.assets(memo)
    end
  end

  def checklist
    return if !Setting.get('checklist')

    record = ticket.checklist
    return if record.blank?

    {
      complete: record.complete,
      total:    record.total,
    }
  end
end

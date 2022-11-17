# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::Create < Service::BaseWithCurrentUser
  def execute(article_data:)
    ticket_id = article_data.delete(:ticket_id)
    form_id = article_data.delete(:form_id)

    Ticket::Article.new(article_data).tap do |article|
      article.ticket_id = ticket_id
      article.attachments = attachments(article, form_id)

      article.save!

      if article_data[:time_unit].present?
        time_accounting(article, article_data[:time_unit])
      end

      return article if form_id.blank?

      form_id_cleanup(form_id)
    end
  end

  private

  def attachments(article, form_id)
    attachments_inline = []
    if article.body && article.content_type&.match?(%r{text/html}i)
      (article.body, attachments_inline) = HtmlSanitizer.replace_inline_images(article.body, article.ticket_id)
    end

    # find attachments in upload cache
    attachments = form_id ? UploadCache.new(form_id).attachments : []

    # store inline attachments
    attachments_inline.each do |attachment_inline|
      attachments.push({
                         data:        attachment_inline[:data],
                         filename:    attachment_inline[:filename],
                         preferences: attachment_inline[:preferences],
                       })
    end

    attachments
  end

  def time_accounting(article, time_unit)
    Ticket::TimeAccounting.create!(
      ticket_id:         article.ticket_id,
      ticket_article_id: article.id,
      time_unit:         time_unit,
    )
  end

  def form_id_cleanup(form_id)
    # clear in-progress state from taskbar
    Taskbar
      .where(user_id: current_user.id)
      .first { |taskbar| taskbar.persisted_form_id == form_id }&.update!(state: {})

    # remove temporary attachment cache
    UploadCache.new(form_id).destroy
  end
end

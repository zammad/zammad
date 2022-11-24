# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::Create < Service::BaseWithCurrentUser
  def execute(article_data:)
    ticket_id = article_data.delete(:ticket_id)
    form_id = article_data.delete(:form_id)

    if Ticket.find(ticket_id).nil?
      raise ActiveRecord::RecordNotFound, "Ticket #{ticket_id} for new article could not be found."
    end

    Ticket::Article.new(article_data).tap do |article|
      transform_article(article, ticket_id, form_id)

      article.save!

      if article_data[:time_unit].present?
        time_accounting(article, article_data[:time_unit])
      end

      return article if form_id.blank?

      form_id_cleanup(form_id)
    end
  end

  private

  def transform_article(article, ticket_id, form_id)
    article.ticket_id = ticket_id
    article.attachments = attachments(article, form_id)

    transform_to_from(article)

    article
  end

  def transform_to_from(article)
    ticket = Ticket.find(article.ticket_id)

    customer_display_name = display_name(ticket.customer)
    group_name = ticket.group.name

    if article.sender.name.eql?('Customer')
      article.from = customer_display_name
      article.to = group_name
    else
      article.to = customer_display_name
      article.from = group_name
    end
  end

  def display_name(user)
    if user.fullname.present? && user.email.present?
      return Mail::Address.new.tap do |addr|
               addr.display_name = user.fullname
               addr.address = user.email
             end.format
    end

    return user.fullname if user.fullname.present?

    display_name_fallback(user)
  end

  def display_name_fallback(user)
    return user.email if user.email.present?
    return user.phone if user.phone.present?
    return user.login if user.login.present?

    '???'
  end

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

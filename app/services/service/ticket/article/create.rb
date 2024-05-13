# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::Create < Service::BaseWithCurrentUser
  def execute(article_data:, ticket:)
    article_data.delete(:ticket_id)

    attachments_raw = article_data.delete(:attachments) || {}
    time_unit       = article_data.delete(:time_unit)
    subtype         = article_data.delete(:subtype)

    preprocess_article_data(article_data, ticket)

    ticket.articles.new(article_data).tap do |article|
      article.check_mentions_raises_error = true

      transform_article(article, attachments_raw, subtype)

      article.save!

      time_accounting(article, time_unit)
      form_id_cleanup(attachments_raw)
    end
  end

  private

  def preprocess_article_data(article_data, ticket)
    preprocess_type(article_data)
    preprocess_to_cc(article_data)
    preprocess_sender(article_data, ticket)
    preprocess_for_customer(article_data, ticket)
  end

  def preprocess_type(article_data)
    type_name = article_data[:type] || 'note'

    article_data[:type] = Ticket::Article::Type.lookup(name: type_name)
  end

  def preprocess_to_cc(article_data)
    %i[to cc].each do |field|
      article_data[field] = article_data[field].join(', ') if article_data[field].is_a? Array
      article_data[field] ||= ''
    end
  end

  def preprocess_sender(article_data, ticket)
    sender_name = if agent_on_ticket?(ticket)
                    article_data[:sender].presence || 'Agent'
                  else
                    'Customer'
                  end

    article_data[:sender] = Ticket::Article::Sender.lookup(name: sender_name)
  end

  def preprocess_for_customer(article_data, ticket)
    return if agent_on_ticket?(ticket)

    if %w[note web].exclude? article_data[:type]&.name
      article_data[:type] = Ticket::Article::Type.lookup(name: 'note')
    end

    article_data.delete :origin_by_id

    article_data[:internal] = false
  end

  def transform_article(article, attachments_raw, subtype)
    transform_attachments(article, attachments_raw)
    transform_subtype(article, subtype)
  end

  def transform_subtype(article, subtype)
    article.preferences[:subtype] = subtype if subtype.present?
  end

  def transform_attachments(article, attachments_raw)
    inline_attachments = []
    if article.body && article.content_type&.include?('text/html')
      (article.body, inline_attachments) = HtmlSanitizer.replace_inline_images(article.body, article.ticket_id)
    end

    article.attachments = attached_attachments(attachments_raw) + inline_attachments_map(inline_attachments)
  end

  def inline_attachments_map(inline_attachments)
    inline_attachments.map do |elem|
      elem.slice(:data, :filename, :preferences)
    end
  end

  def attached_attachments(attachments_raw)
    form_id   = attachments_raw[:form_id]
    file_meta = attachments_raw[:files]

    return [] if form_id.blank?

    UploadCache
      .new(form_id)
      .attachments
      .select do |elem|
        file_meta.any? { |file| check_attachment_match(elem, file) }
      end
  end

  def check_attachment_match(attachment, file)
    if file[:type].present? && attachment[:preferences].present? && attachment[:preferences]['Content-Type'].present?
      file[:name] == attachment[:filename] && file[:type] == attachment[:preferences]['Content-Type']
    end

    file[:name] == attachment[:filename]
  end

  def time_accounting(article, time_unit)
    return if time_unit.blank?

    time_accounting = Ticket::TimeAccounting.new(
      ticket_id:         article.ticket_id,
      ticket_article_id: article.id,
      time_unit:         time_unit,
    )

    policy = Ticket::TimeAccountingPolicy.new(current_user, time_accounting)

    if !policy.create?
      raise policy.custom_exception || __('Not authorized')
    end

    time_accounting.save!
  end

  def form_id_cleanup(attachments_raw)
    form_id = attachments_raw[:form_id]
    return if form_id.blank?

    # clear in-progress state from taskbar
    Taskbar
      .where(user_id: current_user.id)
      .first { |taskbar| taskbar.persisted_form_id == form_id }&.update!(state: {})

    # remove temporary attachment cache
    UploadCache
      .new(form_id)
      .destroy
  end

  def agent_on_ticket?(_ticket)
    current_user.permissions?('ticket.agent')
  end

  def display_name(user)
    if user.fullname.present? && user.email.present?
      return Channel::EmailBuild.recipient_line user.fullname, user.email
    end

    return user.fullname if user.fullname.present?

    display_name_fallback(user)
  end

  def display_name_fallback(user)
    user.email.presence || user.phone.presence || user.mobile.presence || user.login.presence || '-'
  end
end

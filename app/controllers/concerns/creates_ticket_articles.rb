# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CreatesTicketArticles # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  private

  def article_create(ticket, params)

    # create article if given
    form_id = params.delete(:form_id)
    subtype = params.delete(:subtype)

    # check min. params
    raise Exceptions::UnprocessableEntity, __("Need at least an 'article body' field.") if params[:body].nil?

    # fill default values
    if params[:type_id].blank? && params[:type].blank?
      params[:type_id] = Ticket::Article::Type.lookup(name: 'note').id
    end
    if params[:sender_id].blank? && params[:sender].blank?
      sender = 'Customer'
      if current_user.permissions?('ticket.agent')
        sender = 'Agent'
      end
      params[:sender_id] = Ticket::Article::Sender.lookup(name: sender).id
    end

    # remember time accounting values
    accounted_time_params = article_create_accounted_time_params(params)
    clean_params          = Ticket::Article.association_name_to_id_convert(params)
    clean_params          = Ticket::Article.param_cleanup(clean_params, true)

    # overwrite params
    if !current_user.permissions?('ticket.agent')
      clean_params[:sender_id] = Ticket::Article::Sender.lookup(name: 'Customer').id
      clean_params.delete(:sender)
      clean_params.delete(:origin_by_id)
      type = Ticket::Article::Type.lookup(id: clean_params[:type_id])
      if !type.name.match?(%r{^(note|web)$})
        clean_params[:type_id] = Ticket::Article::Type.lookup(name: 'note').id
      end
      clean_params.delete(:type)
      clean_params[:internal] = false
    end

    article                                    = Ticket::Article.new(clean_params)
    article.ticket_id                          = ticket.id
    article.check_mentions_raises_error        = true
    article.check_email_recipient_raises_error = true

    # create article with attachments
    article = article_create_attachments(form_id, article, ticket, params)

    # set subtype of present
    article.preferences[:subtype] = subtype if subtype.present?

    article.save!

    # account time
    if accounted_time_params.present?
      clean_accounted_time_params = Ticket::TimeAccounting.association_name_to_id_convert(accounted_time_params)
      clean_accounted_time_params = Ticket::TimeAccounting.param_cleanup(clean_accounted_time_params, true)

      time_accounting = Ticket::TimeAccounting.new(
        ticket_id:         article.ticket_id,
        ticket_article_id: article.id,
        **clean_accounted_time_params,
      )

      authorize! time_accounting, :create?

      time_accounting.save!
    end

    return article if form_id.blank?

    # clear in-progress state from taskbar
    Taskbar
      .where(user_id: current_user.id)
      .find { |taskbar| taskbar.persisted_form_id == form_id }
      &.update!(state: {})

    # remove temporary attachment cache
    UploadCache.new(form_id).destroy

    article
  end

  def article_create_accounted_time_params(params)
    return if params[:time_unit].blank?

    {
      time_unit: params[:time_unit],
      type_id:   params[:accounted_time_type_id],
      type:      params[:accounted_time_type],
    }
  end

  def article_create_attachments_form_id(form_id, attachments_inline)
    return [] if !form_id

    UploadCache
      .new(form_id)
      .attachments
      .reject do |elem|
        UploadCache.files_include_attachment?(attachments_inline, elem) || elem.inline?
      end
  end

  def article_create_attachments_params(params)
    attachments = []

    return attachments if params[:attachments].blank?

    required_keys    = %w[mime-type filename data]
    preferences_keys = %w[charset mime-type]
    params[:attachments].each_with_index do |attachment, index|

      # validation
      required_keys.each do |key|
        next if attachment[key]

        raise Exceptions::UnprocessableEntity, "Attachment needs '#{key}' param for attachment with index '#{index}'"
      end

      preferences = {}
      preferences_keys.each do |key|
        next if !attachment[key]

        store_key = key.tr('-', '_').camelize.gsub(%r{(.+)([A-Z])}, '\1_\2').tr('_', '-')
        preferences[store_key] = attachment[key]
      end

      begin
        base64_data = attachment[:data].gsub(%r{[\r\n]}, '')
        attachment_data = Base64.strict_decode64(base64_data)
      rescue ArgumentError
        raise Exceptions::UnprocessableEntity, "Invalid base64 for attachment with index '#{index}'"
      end

      attachments << {
        data:        attachment_data,
        filename:    attachment[:filename],
        preferences: preferences,
      }
    end

    attachments
  end

  def article_create_attachments(form_id, article, ticket, params)

    # store dataurl images to store
    attachments_inline = []
    if article.body && article.content_type =~ %r{text/html}i
      (article.body, attachments_inline) = HtmlSanitizer.replace_inline_images(article.body, ticket.id)
    end

    # find attachments in upload cache
    attachments = []
    attachments += article_create_attachments_form_id(form_id, attachments_inline)

    # store inline attachments
    attachments_inline.each do |attachment|
      attachments << {
        data:        attachment[:data],
        filename:    attachment[:filename],
        preferences: attachment[:preferences],
      }
    end

    attachments += article_create_attachments_params(params)

    article.attachments = attachments
    article
  end
end

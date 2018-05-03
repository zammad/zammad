module CreatesTicketArticles
  extend ActiveSupport::Concern

  private

  def article_create(ticket, params)

    # create article if given
    form_id = params[:form_id]
    params.delete(:form_id)
    subtype = params.delete(:subtype)

    # check min. params
    raise Exceptions::UnprocessableEntity, 'Need at least article: { body: "some text" }' if !params[:body]

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

    # remember time accounting
    time_unit = params[:time_unit]

    clean_params = Ticket::Article.association_name_to_id_convert(params)
    clean_params = Ticket::Article.param_cleanup(clean_params, true)

    # overwrite params
    if !current_user.permissions?('ticket.agent')
      clean_params[:sender_id] = Ticket::Article::Sender.lookup(name: 'Customer').id
      clean_params.delete(:sender)
      clean_params.delete(:origin_by_id)
      type = Ticket::Article::Type.lookup(id: clean_params[:type_id])
      if !type.name.match?(/^(note|web)$/)
        clean_params[:type_id] = Ticket::Article::Type.lookup(name: 'note').id
      end
      clean_params.delete(:type)
      clean_params[:internal] = false
    end

    article = Ticket::Article.new(clean_params)
    article.ticket_id = ticket.id

    # store dataurl images to store
    attachments_inline = []
    if article.body && article.content_type =~ %r{text/html}i
      (article.body, attachments_inline) = HtmlSanitizer.replace_inline_images(article.body, ticket.id)
    end

    # find attachments in upload cache
    if form_id
      article.attachments = Store.list(
        object: 'UploadCache',
        o_id: form_id,
      )
    end

    # set subtype of present
    article.preferences[:subtype] = subtype if subtype.present?

    article.save!

    # store inline attachments
    attachments_inline.each do |attachment|
      Store.add(
        object: 'Ticket::Article',
        o_id: article.id,
        data: attachment[:data],
        filename: attachment[:filename],
        preferences: attachment[:preferences],
      )
    end

    # add attachments as param
    if params[:attachments].present?
      params[:attachments].each_with_index do |attachment, index|

        # validation
        ['mime-type', 'filename', 'data'].each do |key|
          next if attachment[key]
          raise Exceptions::UnprocessableEntity, "Attachment needs '#{key}' param for attachment with index '#{index}'"
        end

        preferences = {}
        ['charset', 'mime-type'].each do |key|
          next if !attachment[key]
          store_key = key.tr('-', '_').camelize.gsub(/(.+)([A-Z])/, '\1_\2').tr('_', '-')
          preferences[store_key] = attachment[key]
        end

        if !attachment[:data].match?(%r{^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$})
          raise Exceptions::UnprocessableEntity, "Invalid base64 for attachment with index '#{index}'"
        end

        Store.add(
          object: 'Ticket::Article',
          o_id: article.id,
          data: Base64.decode64(attachment[:data]),
          filename: attachment[:filename],
          preferences: preferences,
        )
      end
    end

    # account time
    if time_unit.present?
      Ticket::TimeAccounting.create!(
        ticket_id: article.ticket_id,
        ticket_article_id: article.id,
        time_unit: time_unit
      )
    end

    return article if form_id.blank?

    # clear in-progress state from taskbar
    Taskbar
      .where(user_id: current_user.id)
      .first { |taskbar| taskbar.persisted_form_id == form_id }
      &.update!(state: {})

    # remove attachments from upload cache
    Store.remove(
      object: 'UploadCache',
      o_id: form_id,
    )

    article
  end

end

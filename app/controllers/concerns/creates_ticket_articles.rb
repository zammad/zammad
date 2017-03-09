module CreatesTicketArticles
  extend ActiveSupport::Concern

  private

  def article_create(ticket, params)

    # create article if given
    form_id = params[:form_id]
    params.delete(:form_id)

    # check min. params
    raise Exceptions::UnprocessableEntity, 'Need at least article: { body: "some text" }' if !params[:body]

    # fill default values
    if params[:type_id].empty? && params[:type].empty?
      params[:type_id] = Ticket::Article::Type.lookup(name: 'note').id
    end
    if params[:sender_id].empty? && params[:sender].empty?
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
      type = Ticket::Article::Type.lookup(id: clean_params[:type_id])
      if type.name !~ /^(note|web)$/
        clean_params[:type_id] = Ticket::Article::Type.lookup(name: 'note').id
      end
      clean_params.delete(:type)
      clean_params[:internal] = false
    end

    article = Ticket::Article.new(clean_params)
    article.ticket_id = ticket.id

    # store dataurl images to store
    if form_id && article.body && article.content_type =~ %r{text/html}i
      article.body.gsub!( %r{(<img\s.+?src=")(data:image/(jpeg|png);base64,.+?)">}i ) { |_item|
        file_attributes = StaticAssets.data_url_attributes($2)
        cid = "#{ticket.id}.#{form_id}.#{rand(999_999)}@#{Setting.get('fqdn')}"
        headers_store = {
          'Content-Type' => file_attributes[:mime_type],
          'Mime-Type' => file_attributes[:mime_type],
          'Content-ID' => cid,
          'Content-Disposition' => 'inline',
        }
        store = Store.add(
          object: 'UploadCache',
          o_id: form_id,
          data: file_attributes[:content],
          filename: cid,
          preferences: headers_store
        )
        "#{$1}cid:#{cid}\">"
      }
    end

    # find attachments in upload cache
    if form_id
      article.attachments = Store.list(
        object: 'UploadCache',
        o_id: form_id,
      )
    end
    article.save!

    # account time
    if time_unit.present?
      Ticket::TimeAccounting.create!(
        ticket_id: article.ticket_id,
        ticket_article_id: article.id,
        time_unit: time_unit
      )
    end

    # remove attachments from upload cache
    return article if !form_id

    Store.remove(
      object: 'UploadCache',
      o_id: form_id,
    )

    article
  end
end

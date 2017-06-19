# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TicketArticlesController < ApplicationController
  include CreatesTicketArticles

  prepend_before_action :authentication_check

  # GET /articles
  def index
    permission_check('admin')
    model_index_render(Ticket::Article, params)
  end

  # GET /articles/1
  def show
    article = Ticket::Article.find(params[:id])
    access!(article, 'read')

    if params[:expand]
      result = article.attributes_with_association_names
      render json: result, status: :ok
      return
    end

    if params[:full]
      full = Ticket::Article.full(params[:id])
      render json: full
      return
    end

    render json: article.attributes_with_association_names
  end

  # GET /ticket_articles/by_ticket/1
  def index_by_ticket
    ticket = Ticket.find(params[:id])
    access!(ticket, 'read')

    articles = []

    if params[:expand]
      ticket.articles.each { |article|

        # ignore internal article if customer is requesting
        next if article.internal == true && current_user.permissions?('ticket.customer')
        result = article.attributes_with_association_names
        articles.push result
      }

      render json: articles, status: :ok
      return
    end

    if params[:full]
      assets = {}
      record_ids = []
      ticket.articles.each { |article|

        # ignore internal article if customer is requesting
        next if article.internal == true && current_user.permissions?('ticket.customer')

        record_ids.push article.id
        assets = article.assets({})
      }
      render json: {
        record_ids: record_ids,
        assets: assets,
      }
      return
    end

    ticket.articles.each { |article|

      # ignore internal article if customer is requesting
      next if article.internal == true && current_user.permissions?('ticket.customer')
      articles.push article.attributes_with_association_names
    }
    render json: articles
  end

  # POST /articles
  def create
    ticket = Ticket.find(params[:ticket_id])
    access!(ticket, 'create')
    article = article_create(ticket, params)

    if params[:expand]
      result = article.attributes_with_association_names
      render json: result, status: :created
      return
    end

    if params[:full]
      full = Ticket::Article.full(params[:id])
      render json: full, status: :created
      return
    end

    render json: article.attributes_with_association_names, status: :created
  end

  # PUT /articles/1
  def update
    article = Ticket::Article.find(params[:id])
    access!(article, 'change')

    if !current_user.permissions?('ticket.agent') && !current_user.permissions?('admin')
      raise Exceptions::NotAuthorized, 'Not authorized (ticket.agent or admin permission required)!'
    end

    clean_params = Ticket::Article.association_name_to_id_convert(params)
    clean_params = Ticket::Article.param_cleanup(clean_params, true)

    article.update_attributes!(clean_params)

    if params[:expand]
      result = article.attributes_with_association_names
      render json: result, status: :ok
      return
    end

    if params[:full]
      full = Ticket::Article.full(params[:id])
      render json: full, status: :ok
      return
    end

    render json: article.attributes_with_association_names, status: :ok
  end

  # DELETE /articles/1
  def destroy
    article = Ticket::Article.find(params[:id])
    access!(article, 'delete')

    if current_user.permissions?('admin')
      article.destroy!
      head :ok
      return
    end

    if current_user.permissions?('ticket.agent') && article.created_by_id == current_user.id && article.type.name == 'note'
      article.destroy!
      head :ok
      return
    end

    raise Exceptions::NotAuthorized, 'Not authorized (admin permission required)!'
  end

  # DELETE /ticket_attachment_upload
  def ticket_attachment_upload_delete
    if params[:store_id]
      Store.remove_item(params[:store_id])
      render json: {
        success: true,
      }
      return
    elsif params[:form_id]
      Store.remove(
        object: 'UploadCache',
        o_id:   params[:form_id],
      )
      render json: {
        success: true,
      }
      return
    end

    render json: { message: 'No such store_id or form_id!' }, status: :unprocessable_entity
  end

  # POST /ticket_attachment_upload
  def ticket_attachment_upload_add

    # store file
    file = params[:File]
    content_type = file.content_type
    if !content_type || content_type == 'application/octet-stream'
      content_type = if MIME::Types.type_for(file.original_filename).first
                       MIME::Types.type_for(file.original_filename).first.content_type
                     else
                       'application/octet-stream'
                     end
    end
    headers_store = {
      'Content-Type' => content_type
    }
    store = Store.add(
      object: 'UploadCache',
      o_id: params[:form_id],
      data: file.read,
      filename: file.original_filename,
      preferences: headers_store
    )

    # return result
    render json: {
      success: true,
      data: {
        store_id: store.id,
        filename: file.original_filename,
        size: store.size,
      }
    }
  end

  # GET /ticket_attachment/:ticket_id/:article_id/:id
  def attachment
    ticket = Ticket.lookup(id: params[:ticket_id])
    access!(ticket, 'read')

    article = Ticket::Article.find(params[:article_id])
    if ticket.id != article.ticket_id

      # check if requested ticket got merged
      if ticket.state.state_type.name != 'merged'
        raise Exceptions::NotAuthorized, 'No access, article_id/ticket_id is not matching.'
      end

      ticket = article.ticket
      access!(ticket, 'read')
    end

    list = article.attachments || []
    access = false
    list.each { |item|
      if item.id.to_i == params[:id].to_i
        access = true
      end
    }
    raise Exceptions::NotAuthorized, 'Requested file id is not linked with article_id.' if !access

    # find file
    file = Store.find(params[:id])

    disposition = sanitized_disposition

    send_data(
      file.content,
      filename: file.filename,
      type: file.preferences['Content-Type'] || file.preferences['Mime-Type'],
      disposition: disposition
    )
  end

  # GET /ticket_article_plain/1
  def article_plain
    article = Ticket::Article.find(params[:id])
    access!(article, 'read')

    file = article.as_raw

    # find file
    return if !file

    send_data(
      file.content,
      filename: file.filename,
      type: 'message/rfc822',
      disposition: 'inline'
    )
  end

  private

  def sanitized_disposition
    disposition = params.fetch(:disposition, 'inline')
    valid_disposition = %w(inline attachment)
    return disposition if valid_disposition.include?(disposition)
    raise Exceptions::NotAuthorized, "Invalid disposition #{disposition} requested. Only #{valid_disposition.join(', ')} are valid."
  end
end

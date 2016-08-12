# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TicketArticlesController < ApplicationController
  before_action :authentication_check

  # GET /articles
  def index
    permission_check('admin')
    model_index_render(Ticket::Article, params)
  end

  # GET /articles/1
  def show

    # permission check
    article = Ticket::Article.find(params[:id])
    article_permission(article)

    if params[:expand]
      result = article.attributes_with_relation_names

      # add attachments
      result[:attachments] = article.attachments

      render json: result, status: :ok
      return
    end

    if params[:full]
      full = Ticket::Article.full(params[:id])
      render json: full
      return
    end

    render json: article.attributes_with_relation_names
  end

  # GET /ticket_articles/by_ticket/1
  def index_by_ticket

    # permission check
    ticket = Ticket.find(params[:id])
    ticket_permission(ticket)

    articles = []

    if params[:expand]
      ticket.articles.each { |article|

        # ignore internal article if customer is requesting
        next if article.internal == true && current_user.permissions?('ticket.customer')

        result = article.attributes_with_relation_names

        # add attachments
        result[:attachments] = article.attachments
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

      articles.push article.attributes_with_relation_names
    }
    render json: articles
  end

  # POST /articles
  def create
    form_id = params[:form_id]

    clean_params = Ticket::Article.param_association_lookup(params)
    clean_params = Ticket::Article.param_cleanup(clean_params, true)
    article = Ticket::Article.new(clean_params)

    # permission check
    article_permission(article)

    # find attachments in upload cache
    if form_id
      article.attachments = Store.list(
        object: 'UploadCache',
        o_id: form_id,
      )
    end

    if article.save

      # remove attachments from upload cache
      Store.remove(
        object: 'UploadCache',
        o_id: form_id,
      )

      render json: article, status: :created
    else
      render json: article.errors, status: :unprocessable_entity
    end
  end

  # PUT /articles/1
  def update

    # permission check
    article = Ticket::Article.find(params[:id])
    article_permission(article)

    clean_params = Ticket::Article.param_association_lookup(params)
    clean_params = Ticket::Article.param_cleanup(clean_params, true)

    if article.update_attributes(clean_params)
      render json: article, status: :ok
    else
      render json: article.errors, status: :unprocessable_entity
    end
  end

  # DELETE /articles/1
  def destroy
    article = Ticket::Article.find(params[:id])
    article_permission(article)
    article.destroy

    head :ok
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

    # permission check
    ticket = Ticket.lookup(id: params[:ticket_id])
    if !ticket_permission(ticket)
      raise Exceptions::NotAuthorized, 'No such ticket.'
    end
    article = Ticket::Article.find(params[:article_id])
    if ticket.id != article.ticket_id
      raise Exceptions::NotAuthorized, 'No access, article_id/ticket_id is not matching.'
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
    send_data(
      file.content,
      filename: file.filename,
      type: file.preferences['Content-Type'] || file.preferences['Mime-Type'],
      disposition: 'inline'
    )
  end

  # GET /ticket_article_plain/1
  def article_plain

    # permission check
    article = Ticket::Article.find(params[:id])
    article_permission(article)

    list = Store.list(
      object: 'Ticket::Article::Mail',
      o_id: params[:id],
    )

    # find file
    return if !list

    file = Store.find(list.first)
    send_data(
      file.content,
      filename: file.filename,
      type: 'message/rfc822',
      disposition: 'inline'
    )
  end

end

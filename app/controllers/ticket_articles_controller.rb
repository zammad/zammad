# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TicketArticlesController < ApplicationController
  before_action :authentication_check

  # GET /articles
  def index
    @articles = Ticket::Article.all

    render json: @articles
  end

  # GET /articles/1
  def show
    @article = Ticket::Article.find( params[:id] )

    render json: @article
  end

  # POST /articles
  def create
    form_id = params[:ticket_article][:form_id]
    params[:ticket_article].delete(:form_id)
    @article = Ticket::Article.new( Ticket::Article.param_validation( params[:ticket_article] ) )

    # find attachments in upload cache
    if form_id
      @article.attachments = Store.list(
        object: 'UploadCache',
        o_id: form_id,
      )
    end

    if @article.save

      # remove attachments from upload cache
      Store.remove(
        object: 'UploadCache',
        o_id: form_id,
      )

      render json: @article, status: :created
    else
      render json: @article.errors, status: :unprocessable_entity
    end
  end

  # PUT /articles/1
  def update
    @article = Ticket::Article.find( params[:id] )

    if @article.update_attributes( Ticket::Article.param_validation( params[:ticket_article] ) )
      render json: @article, status: :ok
    else
      render json: @article.errors, status: :unprocessable_entity
    end
  end

  # DELETE /articles/1
  def destroy
    @article = Ticket::Article.find( params[:id] )
    @article.destroy

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

  # GET /ticket_attachment/1
  def attachment

    # permission check
    ticket = Ticket.find( params[:ticket_id] )
    if !ticket_permission(ticket)
      render( json: 'No such ticket.', status: :unauthorized )
      return
    end
    article = Ticket::Article.find( params[:article_id] )
    if ticket.id != article.ticket_id
      render( json: 'No access, article_id/ticket_id is not matching.', status: :unauthorized )
      return
    end

    list = article.attachments || []
    access = false
    list.each {|item|
      if item.id.to_i == params[:id].to_i
        access = true
      end
    }
    if !access
      render( json: 'Requested file id is not linked with article_id.', status: :unauthorized )
      return
    end

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
    article = Ticket::Article.find( params[:id] )
    return if !ticket_permission( article.ticket )

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

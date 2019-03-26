# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TicketArticlesController < ApplicationController
  include CreatesTicketArticles
  include ClonesTicketArticleAttachments

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

    if response_expand?
      result = article.attributes_with_association_names
      render json: result, status: :ok
      return
    end

    if response_full?
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

    if response_expand?
      ticket.articles.each do |article|

        # ignore internal article if customer is requesting
        next if article.internal == true && current_user.permissions?('ticket.customer')

        result = article.attributes_with_association_names
        articles.push result
      end

      render json: articles, status: :ok
      return
    end

    if response_full?
      assets = {}
      record_ids = []
      ticket.articles.each do |article|

        # ignore internal article if customer is requesting
        next if article.internal == true && current_user.permissions?('ticket.customer')

        record_ids.push article.id
        assets = article.assets({})
      end
      render json: {
        record_ids: record_ids,
        assets:     assets,
      }, status: :ok
      return
    end

    ticket.articles.each do |article|

      # ignore internal article if customer is requesting
      next if article.internal == true && current_user.permissions?('ticket.customer')

      articles.push article.attributes_with_association_names
    end
    render json: articles, status: :ok
  end

  # POST /articles
  def create
    ticket = Ticket.find(params[:ticket_id])
    access!(ticket, 'create')
    article = article_create(ticket, params)

    if response_expand?
      result = article.attributes_with_association_names
      render json: result, status: :created
      return
    end

    if response_full?
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

    # only apply preferences changes (keep not updated keys/values)
    clean_params = article.param_preferences_merge(clean_params)

    article.update!(clean_params)

    if response_expand?
      result = article.attributes_with_association_names
      render json: result, status: :ok
      return
    end

    if response_full?
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

  # POST /ticket_attachment_upload_clone_by_article
  def ticket_attachment_upload_clone_by_article
    article = Ticket::Article.find(params[:article_id])
    access!(article.ticket, 'read')

    render json: {
      attachments: article_attachments_clone(article),
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
    list.each do |item|
      if item.id.to_i == params[:id].to_i
        access = true
      end
    end
    raise Exceptions::NotAuthorized, 'Requested file id is not linked with article_id.' if !access

    # find file
    file = Store.find(params[:id])

    disposition = sanitized_disposition

    content = nil
    if params[:view].present? && file.preferences[:resizable] == true
      if file.preferences[:content_inline] == true && params[:view] == 'inline'
        content = file.content_inline
      elsif file.preferences[:content_preview] == true && params[:view] == 'preview'
        content = file.content_preview
      end
    end

    if content.blank?
      content = file.content
    end

    send_data(
      content,
      filename:    file.filename,
      type:        file.preferences['Content-Type'] || file.preferences['Mime-Type'] || 'application/octet-stream',
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
      filename:    file.filename,
      type:        'message/rfc822',
      disposition: 'inline'
    )
  end

  # @path    [GET] /ticket_articles/import_example
  #
  # @summary          Download of example CSV file.
  # @notes            The requester have 'admin' permissions to be able to download it.
  # @example          curl -u 'me@example.com:test' http://localhost:3000/api/v1/ticket_articles/import_example
  #
  # @response_message 200 File download.
  # @response_message 401 Invalid session.
  def import_example
    permission_check('admin')
    csv_string = Ticket::Article.csv_example(
      col_sep: ',',
    )
    send_data(
      csv_string,
      filename:    'example.csv',
      type:        'text/csv',
      disposition: 'attachment'
    )

  end

  # @path    [POST] /ticket_articles/import
  #
  # @summary          Starts import.
  # @notes            The requester have 'admin' permissions to be create a new import.
  # @example          curl -u 'me@example.com:test' -F 'file=@/path/to/file/ticket_articles.csv' 'https://your.zammad/api/v1/ticket_articles/import?try=true'
  # @example          curl -u 'me@example.com:test' -F 'file=@/path/to/file/ticket_articles.csv' 'https://your.zammad/api/v1/ticket_articles/import'
  #
  # @response_message 201 Import started.
  # @response_message 401 Invalid session.
  def import_start
    permission_check('admin')
    if Setting.get('import_mode') != true
      raise 'Only can import tickets if system is in import mode.'
    end

    string = params[:data]
    if string.blank? && params[:file].present?
      string = params[:file].read.force_encoding('utf-8')
    end
    raise Exceptions::UnprocessableEntity, 'No source data submitted!' if string.blank?

    result = Ticket::Article.csv_import(
      string:       string,
      parse_params: {
        col_sep: ';',
      },
      try:          params[:try],
    )
    render json: result, status: :ok
  end

  private

  def sanitized_disposition
    disposition = params.fetch(:disposition, 'inline')
    valid_disposition = %w[inline attachment]
    return disposition if valid_disposition.include?(disposition)

    raise Exceptions::NotAuthorized, "Invalid disposition #{disposition} requested. Only #{valid_disposition.join(', ')} are valid."
  end
end

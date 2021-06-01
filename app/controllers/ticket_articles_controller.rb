# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketArticlesController < ApplicationController
  include CreatesTicketArticles
  include ClonesTicketArticleAttachments

  prepend_before_action -> { authorize! }, only: %i[index import_example import_start]
  prepend_before_action :authentication_check

  # GET /articles
  def index
    model_index_render(Ticket::Article, params)
  end

  # GET /articles/1
  def show
    article = Ticket::Article.find(params[:id])
    authorize!(article)

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
    authorize!(ticket, :show?)

    articles = []

    if response_expand?
      ticket.articles.each do |article|
        next if !authorized?(article, :show?)

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
        next if !authorized?(article, :show?)

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
      next if !authorized?(article, :show?)

      articles.push article.attributes_with_association_names
    end
    render json: articles, status: :ok
  end

  # POST /articles
  def create
    ticket = Ticket.find(params[:ticket_id])
    authorize!(ticket)
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
    authorize!(article)

    # only update internal and highlight info
    clean_params = {}
    if !params[:internal].nil?
      clean_params[:internal] = params[:internal]
    end
    if params.dig(:preferences, :highlight).present?
      clean_params = article.param_preferences_merge(clean_params.merge(
                                                       preferences: {
                                                         highlight: params[:preferences][:highlight].to_s
                                                       }
                                                     ))
    end

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

  # DELETE /api/v1/ticket_articles/:id
  def destroy
    article = Ticket::Article.find(params[:id])
    authorize!(article)
    article.destroy!
    render json: {}, status: :ok
  end

  # POST /ticket_attachment_upload_clone_by_article
  def ticket_attachment_upload_clone_by_article
    article = Ticket::Article.find(params[:article_id])
    authorize!(article.ticket, :show?)

    render json: {
      attachments: article_attachments_clone(article),
    }
  end

  # GET /ticket_attachment/:ticket_id/:article_id/:id
  def attachment
    ticket = Ticket.lookup(id: params[:ticket_id])
    authorize!(ticket, :show?)

    article = Ticket::Article.find(params[:article_id])
    if ticket.id != article.ticket_id

      # check if requested ticket got merged
      if ticket.state.state_type.name != 'merged'
        raise Exceptions::Forbidden, 'No access, article_id/ticket_id is not matching.'
      end

      ticket = article.ticket
      authorize!(ticket, :show?)
    end

    list = article.attachments || []
    access = false
    list.each do |item|
      if item.id.to_i == params[:id].to_i
        access = true
      end
    end
    raise Exceptions::Forbidden, 'Requested file id is not linked with article_id.' if !access

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
    authorize!(article, :show?)

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
  # @response_message 403 Forbidden / Invalid session.
  def import_example
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
  # @response_message 403 Forbidden / Invalid session.
  def import_start
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

  def retry_security_process
    article = Ticket::Article.find(params[:id])
    authorize!(article, :update?)

    result = SecureMailing.retry(article)

    render json: result
  end

  private

  def sanitized_disposition
    disposition = params.fetch(:disposition, 'inline')
    valid_disposition = %w[inline attachment]
    return disposition if valid_disposition.include?(disposition)

    raise Exceptions::Forbidden, "Invalid disposition #{disposition} requested. Only #{valid_disposition.join(', ')} are valid."
  end
end

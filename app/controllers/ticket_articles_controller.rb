class TicketArticlesController < ApplicationController
  before_filter :authentication_check

  # GET /articles
  def index
    @articles = Ticket::Article.all

    render :json => @articles
  end

  # GET /articles/1
  def show
    @article = Ticket::Article.find(params[:id])

    render :json => @article
  end

  # POST /articles
  def create
    @article = Ticket::Article.new(params[:ticket_article])
    @article.created_by_id = current_user.id
    
    # find attachments in upload cache
    @article['attachments'] = Store.list(
      :object => 'UploadCache::TicketZoom::' + current_user.id.to_s,
      :o_id => @article.ticket_id
    )

    if @article.save

      # remove attachments from upload cache
      Store.remove(
        :object => 'UploadCache::TicketZoom::' + current_user.id.to_s,
        :o_id   => @article.ticket_id
      )
      
      render :json => @article, :status => :created
    else
      render :json => @article.errors, :status => :unprocessable_entity
    end
  end

  # PUT /articles/1
  def update
    @article = Ticket::Article.find(params[:id])

    if @article.update_attributes(params[:ticket_article])
      render :json => @article, :status => :ok
    else
      render :json => @article.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /articles/1
  def destroy
    @article = Ticket::Article.find(params[:id])
    @article.destroy

    head :ok
  end
end

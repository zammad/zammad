class TicketArticlesController < ApplicationController
  before_filter :authentication_check

  # GET /articles
  # GET /articles.json
  def index
    @articles = Ticket::Article.all

    respond_to do |format|
      format.json { render :json => @articles }
    end
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
    @article = Ticket::Article.find(params[:id])

    respond_to do |format|
      format.json { render :json => @article }
    end
  end

  # POST /articles
  # POST /articles.json
  def create
    @article = Ticket::Article.new(params[:ticket_article])
    @article.created_by_id = current_user.id
    
    # find attachments in upload cache
    @article['attachments'] = Store.list(
      :object => 'UploadCache::TicketZoom::' + current_user.id.to_s,
      :o_id => @article.ticket_id
    )

    respond_to do |format|
      if @article.save
        format.json { render :json => @article, :status => :created }
        
        # remove attachments from upload cache
        Store.remove(
          :object => 'UploadCache::TicketZoom::' + current_user.id.to_s,
          :o_id => @article.ticket_id
        )
      else
        format.json { render :json => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /articles/1
  # PUT /articles/1.json
  def update
    @article = Ticket::Article.find(params[:id])

    respond_to do |format|
      if @article.update_attributes(params[:ticket_article])
        format.json { render :json => @article, :status => :ok }
      else
        format.json { render :json => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.json
  def destroy
    @article = Ticket::Article.find(params[:id])
    @article.destroy

    respond_to do |format|
      format.json { head :ok }
    end
  end
end

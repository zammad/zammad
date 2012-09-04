class TicketsController < ApplicationController
  before_filter :authentication_check

  # GET /tickets
  def index
    @tickets = Ticket.all

    render :json => @tickets
  end

  # GET /tickets/1
  def show
    @ticket = Ticket.find(params[:id])

    # permissin check
    return if !ticket_permission(@ticket)

    render :json => @ticket
  end

  # POST /tickets
  def create
    @ticket = Ticket.new(params[:ticket])
    @ticket.created_by_id = current_user.id

    # check if article is given
    if !params[:article]
      render :json => 'article hash is missing', :status => :unprocessable_entity
      return
    end

    # create ticket
    if !@ticket.save
      render :json => @ticket.errors, :status => :unprocessable_entity
      return
    end
    
    # create article if given
    if params[:article]
      @article = Ticket::Article.new(params[:article])
      @article.created_by_id = params[:article][:created_by_id] || current_user.id
      @article.ticket_id     = @ticket.id
    
      # find attachments in upload cache
      @article['attachments'] = Store.list(
        :object => 'UploadCache::TicketZoom::' + current_user.id.to_s,
        :o_id => @article.ticket_id
      )
      if !@article.save
        render :json => @article.errors, :status => :unprocessable_entity
        return
      end
      
      # remove attachments from upload cache
      Store.remove(
        :object => 'UploadCache::TicketZoom::' + current_user.id.to_s,
        :o_id   => @article.ticket_id
      )
    end

    render :json => @ticket, :status => :created
  end

  # PUT /tickets/1
  def update
    @ticket = Ticket.find(params[:id])

    # permissin check
    return if !ticket_permission(@ticket)

    if @ticket.update_attributes(params[:ticket])
      render :json => @ticket, :status => :ok
    else
      render :json => @ticket.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /tickets/1
  def destroy
    @ticket = Ticket.find(params[:id])

    # permissin check
    return if !ticket_permission(@ticket)

    @ticket.destroy

    head :ok
  end
end

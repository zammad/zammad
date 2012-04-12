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

    render :json => @ticket
  end

  # POST /tickets
  def create
    @ticket = Ticket.new(params[:ticket])
    @ticket.created_by_id = current_user.id

    if @ticket.save
      render :json => @ticket, :status => :created
    else
      render :json => @ticket.errors, :status => :unprocessable_entity
    end
  end

  # PUT /tickets/1
  def update
    @ticket = Ticket.find(params[:id])

    if @ticket.update_attributes(params[:ticket])
      render :json => @ticket, :status => :ok
    else
      render :json => @ticket.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /tickets/1
  def destroy
    @ticket = Ticket.find(params[:id])
    @ticket.destroy

    head :ok
  end
end

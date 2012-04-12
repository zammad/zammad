class TicketPrioritiesController < ApplicationController
  before_filter :authentication_check

  # GET /ticket_priorities
  def index
    @ticket_priorities = Ticket::Priority.all

    render :json => @ticket_priorities
  end

  # GET /ticket_priorities/1
  def show
    @ticket_priority = Ticket::Priority.find(params[:id])

    render :json => @ticket_priority
  end

  # POST /ticket_priorities
  def create
    @ticket_priority = Ticket::Priority.new(params[:ticket_priority])

    if @ticket_priority.save
      render :json => @ticket_priority, :status => :created
    else
      render :json => @ticket_priority.errors, :status => :unprocessable_entity
    end
  end

  # PUT /ticket_priorities/1
  def update
    @ticket_priority = Ticket::Priority.find(params[:id])

    if @ticket_priority.update_attributes(params[:ticket_priority])
      render :json => @ticket_priority, :status => :ok
    else
      render :json => @ticket_priority.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /ticket_priorities/1
  def destroy
    @ticket_priority = Ticket::Priority.find(params[:id])
    @ticket_priority.destroy

    head :ok
  end
end

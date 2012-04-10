class TicketPrioritiesController < ApplicationController
  before_filter :authentication_check

  # GET /ticket_priorities
  # GET /ticket_priorities.json
  def index
    @ticket_priorities = Ticket::Priority.all

    respond_to do |format|
      format.json { render :json => @ticket_priorities }
    end
  end

  # GET /ticket_priorities/1
  # GET /ticket_priorities/1.json
  def show
    @ticket_priority = Ticket::Priority.find(params[:id])

    respond_to do |format|
      format.json { render :json => @ticket_priority }
    end
  end

  # POST /ticket_priorities
  # POST /ticket_priorities.json
  def create
    @ticket_priority = Ticket::Priority.new(params[:ticket_priority])

    respond_to do |format|
      if @ticket_priority.save
        format.json { render :json => @ticket_priority, :status => :created }
      else
        format.json { render :json => @ticket_priority.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ticket_priorities/1
  # PUT /ticket_priorities/1.json
  def update
    @ticket_priority = Ticket::Priority.find(params[:id])

    respond_to do |format|
      if @ticket_priority.update_attributes(params[:ticket_priority])
        format.json { render :json => @ticket_priority, :status => :ok }
      else
        format.json { render :json => @ticket_priority.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ticket_priorities/1
  # DELETE /ticket_priorities/1.json
  def destroy
    @ticket_priority = Ticket::Priority.find(params[:id])
    @ticket_priority.destroy

    respond_to do |format|
      format.json { head :ok }
    end
  end
end

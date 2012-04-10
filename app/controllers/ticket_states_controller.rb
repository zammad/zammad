class TicketStatesController < ApplicationController
  before_filter :authentication_check

  # GET /ticket_states
  # GET /ticket_states.json
  def index
    @ticket_states = Ticket::State.all

    respond_to do |format|
      format.json { render :json => @ticket_states }
    end
  end

  # GET /ticket_states/1
  # GET /ticket_states/1.json
  def show
    @ticket_state = Ticket::State.find(params[:id])

    respond_to do |format|
      format.json { render :json => @ticket_state }
    end
  end

  # POST /ticket_states
  # POST /ticket_states.json
  def create
    @ticket_state = Ticket::State.new(params[:ticket_state])

    respond_to do |format|
      if @ticket_state.save
        format.json { render :json => @ticket_state, :status => :created }
      else
        format.json { render :json => @ticket_state.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ticket_states/1
  # PUT /ticket_states/1.json
  def update
    @ticket_state = Ticket::State.find(params[:id])

    respond_to do |format|
      if @ticket_state.update_attributes(params[:ticket_state])
        format.json { render :json => @ticket_state, :status => :ok }
      else
        format.json { render :json => @ticket_state.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ticket_states/1
  # DELETE /ticket_states/1.json
  def destroy
    @ticket_state = Ticket::State.find(params[:id])
    @ticket_state.destroy

    respond_to do |format|
      format.json { head :ok }
    end
  end
end

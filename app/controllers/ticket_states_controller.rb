class TicketStatesController < ApplicationController
  before_filter :authentication_check

  # GET /ticket_states
  def index
    @ticket_states = Ticket::State.all

    render :json => @ticket_states
  end

  # GET /ticket_states/1
  def show
    @ticket_state = Ticket::State.find(params[:id])

    render :json => @ticket_state
  end

  # POST /ticket_states
  def create
    @ticket_state = Ticket::State.new(params[:ticket_state])

    if @ticket_state.save
      render :json => @ticket_state, :status => :created
    else
      render :json => @ticket_state.errors, :status => :unprocessable_entity
    end
  end

  # PUT /ticket_states/1
  def update
    @ticket_state = Ticket::State.find(params[:id])

    if @ticket_state.update_attributes(params[:ticket_state])
      render :json => @ticket_state, :status => :ok
    else
      render :json => @ticket_state.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /ticket_states/1
  def destroy
    @ticket_state = Ticket::State.find(params[:id])
    @ticket_state.destroy

    head :ok
  end
end

class TicketStatesController < ApplicationController
  before_filter :authentication_check

  # GET /ticket_states
  def index
    model_index_render(Ticket::State, params)
  end

  # GET /ticket_states/1
  def show
    model_show_render(Ticket::State, params)
  end

  # POST /ticket_states
  def create
    model_create_render(Ticket::State, params)
  end

  # PUT /ticket_states/1
  def update
    model_update_render(Ticket::State, params)
  end

  # DELETE /ticket_states/1
  def destroy
    model_destory_render(Ticket::State, params)
  end
end

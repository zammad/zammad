class TicketPrioritiesController < ApplicationController
  before_filter :authentication_check

  # GET /ticket_priorities
  def index
    model_index_render(Ticket::Priority, params)
  end

  # GET /ticket_priorities/1
  def show
    model_show_render(Ticket::Priority, params)
  end

  # POST /ticket_priorities
  def create
    model_create_render(Ticket::Priority, params)
  end

  # PUT /ticket_priorities/1
  def update
    model_update_render(Ticket::Priority, params)
  end

  # DELETE /ticket_priorities/1
  def destroy
    model_destory_render(Ticket::Priority, params)
  end
end

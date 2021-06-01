# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketPrioritiesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

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
    model_references_check(Ticket::Priority, params)
    model_destroy_render(Ticket::Priority, params)
  end
end

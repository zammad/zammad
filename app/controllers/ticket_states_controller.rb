# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketStatesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

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
    model_references_check(Ticket::State, params)
    model_destroy_render(Ticket::State, params)
  end
end

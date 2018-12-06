# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TicketStatesController < ApplicationController
  prepend_before_action :authentication_check

  # GET /ticket_states
  def index
    permission_check(['admin.object', 'ticket.agent', 'ticket.customer'])
    model_index_render(Ticket::State, params)
  end

  # GET /ticket_states/1
  def show
    permission_check(['admin.object', 'ticket.agent', 'ticket.customer'])
    model_show_render(Ticket::State, params)
  end

  # POST /ticket_states
  def create
    permission_check('admin.object')
    model_create_render(Ticket::State, params)
  end

  # PUT /ticket_states/1
  def update
    permission_check('admin.object')
    model_update_render(Ticket::State, params)
  end

  # DELETE /ticket_states/1
  def destroy
    permission_check('admin.object')
    return if model_references_check(Ticket::State, params)

    model_destroy_render(Ticket::State, params)
  end
end

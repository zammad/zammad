# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TicketPrioritiesController < ApplicationController
  prepend_before_action :authentication_check

  # GET /ticket_priorities
  def index
    permission_check(['admin.object', 'ticket.agent', 'ticket.customer'])
    model_index_render(Ticket::Priority, params)
  end

  # GET /ticket_priorities/1
  def show
    permission_check(['admin.object', 'ticket.agent', 'ticket.customer'])
    model_show_render(Ticket::Priority, params)
  end

  # POST /ticket_priorities
  def create
    permission_check('admin.object')
    model_create_render(Ticket::Priority, params)
  end

  # PUT /ticket_priorities/1
  def update
    permission_check('admin.object')
    model_update_render(Ticket::Priority, params)
  end

  # DELETE /ticket_priorities/1
  def destroy
    permission_check('admin.object')
    model_references_check(Ticket::Priority, params)
    model_destroy_render(Ticket::Priority, params)
  end
end

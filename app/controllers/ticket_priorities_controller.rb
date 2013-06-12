# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

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
    return if is_not_role('Admin')
    model_create_render(Ticket::Priority, params)
  end

  # PUT /ticket_priorities/1
  def update
    return if is_not_role('Admin')
    model_update_render(Ticket::Priority, params)
  end

  # DELETE /ticket_priorities/1
  def destroy
    return if is_not_role('Admin')
    model_destory_render(Ticket::Priority, params)
  end
end

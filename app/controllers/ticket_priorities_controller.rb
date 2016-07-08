# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TicketPrioritiesController < ApplicationController
  before_action :authentication_check

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
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Ticket::Priority, params)
  end

  # PUT /ticket_priorities/1
  def update
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(Ticket::Priority, params)
  end

  # DELETE /ticket_priorities/1
  def destroy
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_references_check(Ticket::Priority, params)
    model_destory_render(Ticket::Priority, params)
  end
end

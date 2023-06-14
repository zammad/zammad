# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Ticket::TimeAccountingsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(ticket_time_accounting, params)
  end

  def show
    model_show_render(ticket_time_accounting, params)
  end

  def create
    model_create_render(Ticket::TimeAccounting, params)
  end

  def update
    model_update_render(ticket_time_accounting, params)
  end

  def destroy
    model_destroy_render(ticket_time_accounting, params)
  end

  private

  def ticket_time_accounting
    @ticket_time_accounting ||= Ticket.find_by(id: params[:ticket_id]).ticket_time_accounting
  end
end

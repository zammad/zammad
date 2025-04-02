# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TimeAccounting::TypesController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(Ticket::TimeAccounting::Type, params)
  end

  def create
    model_create_render(Ticket::TimeAccounting::Type, params)
  end

  def update
    model_update_render(Ticket::TimeAccounting::Type, params)
  end
end

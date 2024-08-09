# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(Checklist.for_user(current_user), params)
  end

  def show
    model_show_render(Checklist.for_user(current_user), params)
  end

  def create
    model_create_render(Checklist.for_user(current_user), params)
  end

  def update
    model_update_render(Checklist.for_user(current_user), params)
  end

  def destroy
    model_destroy_render(Checklist.for_user(current_user), params)
  end
end

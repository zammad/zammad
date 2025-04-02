# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChecklistItemsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def show
    model_show_render(Checklist::Item, existing_item_params)
  end

  def create
    model_create_render(Checklist::Item, new_item_params)
  end

  def update
    model_update_render(Checklist::Item, existing_item_params)
  end

  def destroy
    model_destroy_render(Checklist::Item, existing_item_params)
  end

  private

  def new_item_params
    params.permit(:text, :checklist_id)
  end

  def existing_item_params
    params.permit(:text, :id, :checked)
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChecklistItemsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def show
    model_show_render(Checklist::Item, existing_item_params)
  end

  def create
    if new_item_params[:ticket_id].present?
      ticket = Ticket.find(new_item_params[:ticket_id])

      ticket.with_lock do
        checklist = ticket.checklist || Checklist.create!(ticket:)
        new_item_params[:checklist_id] = checklist.id
      end

      new_item_params.delete(:ticket_id)
    end

    model_create_render(Checklist::Item, new_item_params)
  end

  def create_bulk
    if create_bulk_params[:ticket_id].present?
      ticket = Ticket.find(create_bulk_params[:ticket_id])

      ticket.with_lock do
        checklist = ticket.checklist || Checklist.create!(ticket:)
        create_bulk_params[:checklist_id] = checklist.id
      end

      create_bulk_params.delete(:ticket_id)
    end

    checklist = Checklist.find(create_bulk_params[:checklist_id])

    created_items = create_bulk_params[:items].map do |item|
      checklist.items.create!(item)
    end

    render json: { success: true, checklist_item_ids: created_items.map(&:id) }, status: :created
  end

  def update
    model_update_render(Checklist::Item, existing_item_params)
  end

  def destroy
    model_destroy_render(Checklist::Item, existing_item_params)
  end

  private

  def new_item_params
    @new_item_params ||= begin
      safe_params = params.permit(:text, :checklist_id, :ticket_id)
      replace_ticket_param_with_checklist(safe_params)
    end
  end

  def create_bulk_params
    @create_bulk_params ||= begin
      safe_params = params.permit(:checklist_id, :ticket_id, items: %i[text])
      replace_ticket_param_with_checklist(safe_params)
    end
  end

  def existing_item_params
    @existing_item_params ||= params.permit(:text, :id, :checked)
  end

  def replace_ticket_param_with_checklist(params)
    return params if params[:ticket_id].blank?

    ticket = Ticket.find(params[:ticket_id])

    ticket.with_lock do
      checklist = ticket.checklist || Checklist.create!(ticket:)
      params[:checklist_id] = checklist.id
    end

    params.delete(:ticket_id)

    params
  end
end

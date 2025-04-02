# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChecklistsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def show
    model_show_render(Checklist, existing_checklist_params)
  end

  def create
    ticket = Ticket.find params[:ticket_id]

    checklist = if params[:template_id].present?
                  template = ChecklistTemplate.find(params[:template_id])
                  Checklist.create_from_template!(ticket, template)
                else
                  Checklist.create_fresh!(ticket)
                end

    render json: { id: checklist.id, assets: checklist.assets({}) }, status: :created
  end

  def update
    model_update_render(Checklist, existing_checklist_params)
  end

  def destroy
    model_destroy_render(Checklist, existing_checklist_params)
  end

  private

  def existing_checklist_params
    params.permit(:id, :name, sorted_item_ids: [])
  end
end

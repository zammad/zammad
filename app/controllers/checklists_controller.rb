# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def show_by_ticket
    checklist = Checklist.find_by ticket_id: params[:ticket_id]

    if checklist
      authorize!(checklist, :show?)
      assets = ApplicationModel::CanAssets.reduce([checklist] + checklist.items, {})
      render json: { id: checklist.id, assets: assets }
      return
    end

    render json: {}
  end

  def show
    model_show_render(Checklist, existing_checklist_params)
  end

  def create
    new_checklist = if params[:template_id].present?
                      ChecklistTemplate.find_by(id: params[:template_id]).create_from_template!(ticket_id: params[:ticket_id])
                    else
                      Checklist.create!(name: '', ticket_id: params[:ticket_id]).tap do |checklist|
                        Checklist::Item.create!(checklist_id: checklist.id, text: '')
                      end
                    end

    new_checklist.reload

    render json: { id: new_checklist.id, assets: new_checklist.assets({}) }, status: :created
  end

  def update
    model_update_render(Checklist, existing_checklist_params)
  end

  def destroy
    model_destroy_render(Checklist, existing_checklist_params)
  end

  private

  def new_checklist_params
    params.permit(:ticket_id, :name)
  end

  def existing_checklist_params
    params.permit(:id, :name, sorted_item_ids: [])
  end
end

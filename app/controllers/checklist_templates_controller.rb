# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistTemplatesController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(ChecklistTemplate, params)
  end

  def show
    model_show_render(ChecklistTemplate, params)
  end

  def create
    checklist_template = ChecklistTemplate.create!(checklist_template_params)
    checklist_template.replace_items!(checklist_template_items_params) if checklist_template_items_params.present?

    render json: checklist_template.attributes_with_association_ids, status: :created
  end

  def update
    checklist_template = ChecklistTemplate.find(params[:id])

    checklist_template.update!(checklist_template_params)
    checklist_template.replace_items!(checklist_template_items_params) if checklist_template_items_params.present?

    render json: checklist_template.attributes_with_association_ids, status: :ok
  end

  def destroy
    model_destroy_render(ChecklistTemplate, params)
  end

  private

  def checklist_template_params
    params.permit(:name, :active)
  end

  def checklist_template_items_params
    @checklist_template_items_params ||= params[:items]
      .presence
      &.compact_blank
  end
end

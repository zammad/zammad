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
    items = params[:items].presence || []

    ChecklistTemplate.create!(
      name:   params[:name],
      active: params[:active],
    ).tap do |cl|
      create_and_sort_checklist_template_items(cl, items)

      render json: cl.attributes_with_association_ids, status: :created
    end
  end

  def update
    checklist_template = ChecklistTemplate.find(params[:id])

    items = params[:items].presence || []

    checklist_template.update!(
      name:   params[:name],
      active: params[:active],
    )

    create_and_sort_checklist_template_items(checklist_template, items)

    render json: checklist_template.attributes_with_association_ids, status: :ok
  end

  def destroy
    model_destroy_render(ChecklistTemplate, params)
  end

  private

  def create_and_sort_checklist_template_items(checklist_template, items)
    return if items.blank?

    checklist_template.items.destroy_all if checklist_template.items.present?
    checklist_template.sorted_item_ids = []

    items.compact_blank.each { |text| ChecklistTemplate::Item.create!(text: text.strip, checklist_template:) }
  end
end

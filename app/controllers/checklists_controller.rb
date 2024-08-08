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
    items = params[:items].presence || []

    Checklist.for_user(current_user).create!(
      name:   params[:name],
      active: params[:active],
    ).tap do |cl|
      create_and_sort_checklist_items(cl, items)

      render json: cl.attributes_with_association_ids, status: :created
    end
  end

  def update
    checklist = Checklist.for_user(current_user).find(params[:id])

    items = params[:items].presence || []

    checklist.update!(
      name:   params[:name],
      active: params[:active],
    )

    create_and_sort_checklist_items(checklist, items)

    render json: checklist.attributes_with_association_ids, status: :ok
  end

  def destroy
    model_destroy_render(Checklist.for_user(current_user), params)
  end

  private

  def create_and_sort_checklist_items(checklist, items)
    return if items.blank?

    checklist.items.destroy_all if checklist.items.present?
    checklist.sorted_item_ids = []

    items.compact_blank.each { |text| Checklist::Item.create!(text: text.strip, checklist:) }
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TicketChecklistItemsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def create
    new_item = checklist.items.create!(checklist_params)

    render json: { id: new_item.id, assets: checklist.assets({}) }
  end

  def update
    checklist_item.update!(checklist_params)

    render json: { success: true }
  end

  def destroy
    checklist_item.destroy!

    render json: { success: true }
  end

  private

  def checklist
    @checklist ||= Checklist.find_by(ticket: params[:ticket_id])
    raise ActiveRecord::RecordNotFound if !@checklist

    @checklist
  end

  def checklist_item
    @checklist_item ||= checklist.items.find_by(id: params[:id])
  end

  def checklist_params
    params.permit(:text, :checked)
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TicketChecklistController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def show
    if checklist
      render json: { id: checklist.id, assets: checklist.assets({}) }
      return
    end

    render json: {}
  end

  def create
    if checklist
      raise Exceptions::UnprocessableEntity, __('Checklist is already created for this ticket')
    end

    new_checklist = if params[:template_id].present?
                      ChecklistTemplate.find_by(id: params[:template_id]).create_from_template!(ticket_id: params[:ticket_id])
                    else
                      Checklist.create!(name: '', ticket_id: params[:ticket_id])
                    end

    render json: { id: new_checklist.id, assets: new_checklist.assets({}) }
  end

  def update
    checklist.update! params.permit(:name, sorted_item_ids: [])

    render json: { id: checklist.id, assets: checklist.assets({}) }
  end

  def destroy
    checklist.destroy!

    render json: { success: true }
  end

  def completed
    render json: {
      completed: checklist&.completed?
    }
  end

  private

  def checklist
    @checklist ||= Checklist.find_by(ticket: params[:ticket_id])
  end
end

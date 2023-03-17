# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TicketSharedDraftZoomController < ApplicationController
  prepend_before_action :authorize!
  prepend_before_action :authentication_check

  def show
    object = ticket.shared_draft

    render json: {
      shared_draft_id: object&.id,
      assets:          object&.assets,
    }
  end

  def update
    if ticket.shared_draft.present?
      object = ticket.shared_draft
      object.update! draft_params
    else
      object = ticket.create_shared_draft! draft_params
    end

    object.attach_upload_cache params[:form_id]

    render json: {
      shared_draft_id: object.id,
      assets:          object.assets,
    }
  end

  def destroy
    object = ticket.shared_draft

    object.destroy!

    render json: {
      shared_draft_id: object.id
    }
  end

  def import_attachments
    new_attachments = ticket.shared_draft.clone_attachments 'UploadCache', params[:form_id]

    render json: {
      attachments: new_attachments
    }
  end

  private

  def ticket
    Ticket.find params[:ticket_id]
  end

  def draft_params
    params.permit ticket_attributes: {}, new_article: {}
  end
end

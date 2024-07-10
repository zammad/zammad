# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TicketsSharedDraftStartsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    drafts = scope

    render json: {
      shared_draft_ids: drafts.map(&:id),
      assets:           ApplicationModel::CanAssets.reduce(drafts),
    }
  end

  def show
    object = scope.find params[:id]

    render json: {
      shared_draft_id:      object.id,
      shared_draft_content: object.content_with_base64,
      assets:               object.assets,
    }
  end

  def create
    object = Service::Ticket::SharedDraft::Start::Create
      .new(current_user, params[:form_id], **safe_params)
      .execute

    render json: {
      shared_draft_id: object.id,
      assets:          object.assets,
    }
  end

  def update
    object = scope.find params[:id]

    Service::Ticket::SharedDraft::Start::Update
      .new(current_user, object, params[:form_id], **safe_params)
      .execute

    render json: {
      shared_draft_id: object.id,
      assets:          object.assets,
    }
  end

  def destroy
    object = scope.find params[:id]

    object.destroy!

    render json: {
      shared_draft_id: object.id
    }
  end

  def import_attachments
    object = scope.find params[:id]

    new_attachments = object.clone_attachments 'UploadCache', params[:form_id], only_attached_attachments: true

    render json: {
      attachments: new_attachments
    }
  end

  private

  def scope
    Ticket::SharedDraftStartPolicy::Scope
      .new(current_user, Ticket::SharedDraftStart)
      .resolve
  end

  def safe_params
    @safe_params ||= params
      .permit(:name, :group_id, content: {})
      .to_hash
      .to_options
      .tap { |elem| elem[:group] = Group.find_by(id: elem.delete(:group_id)) }
  end
end

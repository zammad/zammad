# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TicketsSharedDraftStartsController < ApplicationController
  prepend_before_action :authorize!
  prepend_before_action :authentication_check

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
      shared_draft_content: object.content,
      assets:               object.assets,
    }
  end

  def create
    object = scope.create! safe_params
    object.attach_upload_cache params[:form_id]

    render json: {
      shared_draft_id: object.id,
      assets:          object.assets,
    }
  end

  def update
    object = scope.find params[:id]

    object.update! safe_params
    object.attach_upload_cache params[:form_id]

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

    new_attachments = object.clone_attachments 'UploadCache', params[:form_id]

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
    safe_params = params.permit :name, :group_id, content: {}

    safe_params[:content].delete :group_id

    allowed_groups = current_user.groups_access('create').map(&:id).map(&:to_s)
    group_id       = safe_params[:group_id]&.to_s

    if allowed_groups.exclude? group_id
      raise Exceptions::UnprocessableEntity, __("User does not have access to one of given group IDs: #{group_id}")
    end

    safe_params
  end
end

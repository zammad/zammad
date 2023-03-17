# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::PermissionsController < ApplicationController
  prepend_before_action :authentication_check
  before_action :fetch_object

  def show
    render json: response_hash
  end

  def update
    permissions_params = params.require(:permissions_dialog).permit(permissions: {})

    KnowledgeBase::PermissionsUpdate.new(@object, current_user).update_using_params!(permissions_params)

    render json: response_hash
  end

  private

  def fetch_object
    if params[:knowledge_base_id]
      @object = KnowledgeBase::Category.includes(:permissions).find params[:id]
      authorize @object, :permissions?
    else
      @object = KnowledgeBase.includes(:permissions).find params[:id]
      authorize @object, :update?
    end
  end

  def parent_object
    return if !@object.is_a? KnowledgeBase::Category

    @object.parent || @object.knowledge_base
  end

  def response_hash
    roles_editor = Role.with_permissions('knowledge_base.editor')
    roles_reader = Role.with_permissions('knowledge_base.reader') - roles_editor

    {
      roles_reader: roles_reader.pluck_as_hash(:id, :name),
      roles_editor: roles_editor.pluck_as_hash(:id, :name),
      permissions:  @object.permissions_effective.pluck_as_hash(:id, :access, :role_id),
      inherited:    parent_object&.permissions_effective&.pluck_as_hash(:id, :access, :role_id) || []
    }
  end
end

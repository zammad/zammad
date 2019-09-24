# Copyright (C) 2012-2017 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::BaseController < ApplicationController
  before_action :authentication_check
  before_action :ensure_editor_or_reader
  before_action :ensure_editor, only: %i[create update destroy]

  def show
    model_show_render(klass, params_for_permission)
  end

  def create
    model_create_render(klass, params_for_permission)
  end

  def update
    model_update_render(klass, params_for_permission)
  end

  def destroy
    model_destroy_render(klass, params_for_permission)
  end

  private

  def klass
    @klass ||= controller_path.classify.constantize
  end

  def params_for_permission
    params.permit klass.agent_allowed_params
  end

  def ensure_editor
    permission_check 'knowledge_base.editor'
  end

  def ensure_editor_or_reader
    permission_check 'knowledge_base.*'
  end
end

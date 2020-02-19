# Copyright (C) 2012-2017 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Answer::AttachmentsController < ApplicationController
  prepend_before_action :authentication_check
  prepend_before_action { permission_check('knowledge_base.editor') }

  before_action :fetch_answer

  def create
    @answer.add_attachment params[:file]

    render json: @answer.assets({})
  end

  def destroy
    @answer.remove_attachment params[:id]

    render json: @answer.assets({})
  end

  private

  def fetch_answer
    @answer = KnowledgeBase::Answer.find params[:answer_id]
  end
end

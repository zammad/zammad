# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Answer::AttachmentsController < ApplicationController
  prepend_before_action :authentication_check
  before_action :authorize!
  before_action :fetch_answer

  def create
    @answer.add_attachment params[:file]

    render json: @answer.assets({})
  end

  def destroy
    @answer.remove_attachment params[:id]

    render json: @answer.assets({})
  end

  def clone_to_form
    new_attachments = @answer.clone_attachments('UploadCache', params[:form_id], only_attached_attachments: true)

    render json: {
      attachments: new_attachments
    }
  end

  private

  def fetch_answer
    @answer = KnowledgeBase::Answer.find params[:answer_id]
  end
end

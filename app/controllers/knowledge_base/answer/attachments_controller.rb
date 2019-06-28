# Copyright (C) 2012-2017 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Answer::AttachmentsController < ApplicationController
  prepend_before_action :authentication_check
  prepend_before_action { permission_check('knowledge_base.editor') }

  before_action :fetch_answer

  def create
    file = params[:file]

    Store.add(
      object:      @answer.class.name,
      o_id:        @answer.id,
      data:        file.read,
      filename:    file.original_filename,
      preferences: headers_for_file(file)
    )

    output
  end

  def destroy
    attachment = @answer.attachments.find { |elem| elem.id == params[:id].to_i }

    raise ActiveRecord::RecordNotFound if attachment.nil?

    Store.remove_item(attachment.id)

    output
  end

  private

  def fetch_answer
    @answer = KnowledgeBase::Answer.find params[:answer_id]
  end

  def output
    @answer.touch # rubocop:disable Rails/SkipsModelValidations
    render json: @answer.assets({})
  end

  def headers_for_file(file)
    content_type = file.content_type || 'application/octet-stream'

    if content_type == 'application/octet-stream' && (mime = MIME::Types.type_for(file.original_filename).first)
      content_type = mime
    end

    {
      'Content-Type': content_type
    }
  end
end

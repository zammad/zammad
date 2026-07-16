# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AttachmentsController < ApplicationController
  prepend_before_action :authorize!, only: %i[show destroy destroy_form]
  prepend_before_action :authentication_check, except: %i[show destroy]
  prepend_before_action :authentication_check_only, only: %i[show destroy]

  def show
    return render_calendar_preview if params[:preview].present? && params[:type] == 'calendar'

    view_type = params[:preview] ? 'preview' : nil
    send_data(
      download_file.content(view_type),
      filename:    download_file.filename,
      type:        download_file.content_type,
      disposition: download_file.disposition
    )
  end

  def create
    file = params[:File]
    content_type = file.content_type

    if !content_type || content_type == 'application/octet-stream'
      content_type = if MIME::Types.type_for(file.original_filename).first
                       MIME::Types.type_for(file.original_filename).first.content_type
                     else
                       'application/octet-stream'
                     end
    end

    store = UploadCache.new(params[:form_id]).add(
      filename:      file.original_filename,
      data:          file.read,
      preferences:   {
        'Content-Type' => content_type,
      },
      created_by_id: current_user.id,
    )

    render json: {
      success: true,
      data:    {
        id:          store.id,
        filename:    file.original_filename,
        size:        store.size,
        contentType: store.preferences['Content-Type']
      }
    }
  end

  def destroy
    Store.remove_item(download_file.id)

    render json: {
      success: true,
    }
  end

  def destroy_form
    UploadCache.new(params[:form_id]).destroy

    render json: {
      success: true,
    }
  end

  private

  def render_calendar_preview
    render json: Service::Calendar::IcsFile::Parse.execute(file: download_file), status: :ok
  rescue => e
    logger.error e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def user_not_authorized(e)
    not_found(e)
  end
end

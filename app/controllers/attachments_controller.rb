# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AttachmentsController < ApplicationController
  prepend_before_action :authorize!, only: %i[show destroy]
  prepend_before_action :authentication_check, except: %i[show destroy]
  prepend_before_action :authentication_check_only, only: %i[show destroy]

  def show
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

    headers_store = {
      'Content-Type' => content_type
    }

    store = Store.add(
      object:      'UploadCache',
      o_id:        params[:form_id],
      data:        file.read,
      filename:    file.original_filename,
      preferences: headers_store
    )

    render json: {
      success: true,
      data:    {
        id:       store.id,
        filename: file.original_filename,
        size:     store.size,
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
    Store.remove(
      object: 'UploadCache',
      o_id:   params[:form_id],
    )

    render json: {
      success: true,
    }
  end

  private

  def authorize!
    record = download_file&.store_object&.name&.safe_constantize&.find(download_file.o_id)
    authorize(record) if record
  rescue Pundit::NotAuthorizedError
    raise ActiveRecord::RecordNotFound
  end
end

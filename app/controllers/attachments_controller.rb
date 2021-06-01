# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AttachmentsController < ApplicationController
  prepend_before_action :authentication_check, except: %i[show destroy]
  prepend_before_action :authentication_check_only, only: %i[show destroy]
  before_action :verify_object_permissions, only: %i[show destroy]

  def show
    content   = @file.content_preview if params[:preview] && @file.preferences[:content_preview]
    content ||= @file.content

    send_data(
      content,
      filename:    @file.filename,
      type:        @file.preferences['Content-Type'] || @file.preferences['Mime-Type'] || 'application/octet-stream',
      disposition: sanitized_disposition
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
    Store.remove_item(@file.id)

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

  def sanitized_disposition
    disposition = params.fetch(:disposition, 'inline')
    valid_disposition = %w[inline attachment]
    return disposition if valid_disposition.include?(disposition)

    raise Exceptions::Forbidden, "Invalid disposition #{disposition} requested. Only #{valid_disposition.join(', ')} are valid."
  end

  def verify_object_permissions
    @file = Store.find(params[:id])

    klass = @file&.store_object&.name&.safe_constantize
    return if klass.send("can_#{params[:action]}_attachment?", @file, current_user)

    raise ActiveRecord::RecordNotFound
  end
end

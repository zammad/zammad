class PackagesController < ApplicationController
  before_filter :authentication_check

  # GET /api/packages
  def index
    return if is_not_role('Admin')
    packages = Package.all
    render :json => {
      :packages => packages
    }
  end

  # POST /api/packages
  def create
    return if is_not_role('Admin')

    content_type = request[:content_type]
    puts 'content_type: ' + content_type.inspect
    if !content_type || content_type == 'application/octet-stream'
      if MIME::Types.type_for(params[:qqfile]).first
        content_type = MIME::Types.type_for(params[:qqfile]).first.content_type
      else
        content_type = 'application/octet-stream'
      end
    end
    headers_store = {
      'Content-Type' => content_type
    }
    Store.add(
      :object      => 'PackageUploadCache',
      :o_id        => params[:form_id],
      :data        => request.body.read,
      :filename    => params[:qqfile],
      :preferences => headers_store
    )

    # return result
    render :json => {
      :success  => true,
    }
  end
end
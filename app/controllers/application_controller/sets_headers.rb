module ApplicationController::SetsHeaders
  extend ActiveSupport::Concern

  included do
    before_action :cors_preflight_check
    after_action :set_access_control_headers
  end

  private

  # For all responses in this controller, return the CORS access control headers.
  def set_access_control_headers
    return if @_auth_type != 'token_auth' && @_auth_type != 'basic_auth'

    set_access_control_headers_execute
  end

  def set_access_control_headers_execute
    headers['Access-Control-Allow-Origin']      = '*'
    headers['Access-Control-Allow-Methods']     = 'POST, GET, PUT, DELETE, PATCH, OPTIONS'
    headers['Access-Control-Max-Age']           = '1728000'
    headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control, Accept-Language'
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.
  def cors_preflight_check
    return true if @_auth_type != 'token_auth' && @_auth_type != 'basic_auth'

    cors_preflight_check_execute
  end

  def cors_preflight_check_execute
    return true if request.method != 'OPTIONS'

    headers['Access-Control-Allow-Origin']      = '*'
    headers['Access-Control-Allow-Methods']     = 'POST, GET, PUT, DELETE, PATCH, OPTIONS'
    headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control, Accept-Language'
    headers['Access-Control-Max-Age']           = '1728000'
    render text: '', content_type: 'text/plain'
    false
  end
end

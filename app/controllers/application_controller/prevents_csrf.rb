# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationController::PreventsCsrf
  extend ActiveSupport::Concern

  included do
    # disable Rails default (>= 5.2) CSRF verification because we
    # have an advanced use case with our JS App/SPA and the different
    # Auth mechanisms (e.g. Token- or BasicAuth) that can't be covered
    # with the built-in functionality
    skip_before_action :verify_authenticity_token, raise: false

    # register custom CSRF verification and provisioning functionality
    before_action :verify_csrf_token
    after_action  :set_csrf_token_headers
  end

  private

  def set_csrf_token_headers
    return true if @_auth_type.present? && @_auth_type != 'session'

    # call Rails method to provide CRSF token
    headers['CSRF-TOKEN'] = form_authenticity_token
  end

  def verify_csrf_token
    return true if !protect_against_forgery?
    return true if request.get?
    return true if request.head?
    return true if %w[token_auth basic_auth].include?(@_auth_type)

    # call Rails method to verify CRSF token
    return true if valid_authenticity_token?(session, params[:authenticity_token] || request.headers['X-CSRF-Token'])

    logger.info 'CSRF token verification failed'
    raise Exceptions::NotAuthorized, 'CSRF token verification failed!'
  end
end

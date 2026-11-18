# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Browser single sign-on between Zammad and i-doit up, brokered by the add-on.
#
# login:    i-doit up → Zammad. Accepts a 60s single-use token signed by the
#           add-on, starts a Zammad session for that user and opens the ticket.
# identify: Zammad → i-doit up. Zammad acts as identity provider for the
#           add-on's OAuth flow: it signs the logged-in user for the add-on.
class Integration::IdoitUpSsoController < ApplicationController
  skip_before_action :user_device_log

  SSO_AUDIENCE      = 'zammad-sso'.freeze
  IDENTIFY_AUDIENCE = 'idoit-addon-oauth'.freeze
  TARGET_PATTERN    = %r{\A#ticket/zoom/\d+\z}
  NONCE_PATTERN     = %r{\A[\w-]{16,128}\z}
  JTI_TTL           = 5.minutes

  def login
    raise Exceptions::Forbidden, __('The i-doit up integration is disabled.') if !Setting.get('idoit_up_integration')

    claims = single_use_sso_claims
    start_sso_session(sso_user(claims))

    redirect_to "/#{safe_target(claims['redirect'])}"
  rescue ::IdoitUp::Token::Error, Exceptions::NotAuthorized => e
    logger.warn { "i-doit up SSO login rejected: #{e.message}" }
    redirect_to '/#login'
  end

  def identify
    raise Exceptions::Forbidden, __('The i-doit up integration is disabled.') if !Setting.get('idoit_up_integration')

    nonce = params[:nonce].to_s
    raise Exceptions::UnprocessableContent, __('Invalid nonce.') if !nonce.match?(NONCE_PATTERN)

    user = browser_session_user
    return redirect_to('/#login') if !user
    raise Exceptions::UnprocessableContent, __('Your user has no email address.') if user.email.blank?

    token = ::IdoitUp::Token.sign({ sub: user.email.downcase, name: user.fullname, nonce: nonce }, audience: IDENTIFY_AUDIENCE)
    redirect_to "#{::IdoitUp.addon_endpoint}/oauth/callback?#{{ token: token }.to_query}", allow_other_host: true
  end

  private

  # rubocop:disable Zammad/DetectTranslatableString
  def single_use_sso_claims
    claims = ::IdoitUp::Token.verify(params[:token], audience: SSO_AUDIENCE)
    raise ::IdoitUp::Token::Error, 'Missing token id' if claims['jti'].blank?
    raise ::IdoitUp::Token::Error, 'Token already used' if !Rails.cache.write("idoit_up:sso:#{claims['jti']}", true, unless_exist: true, expires_in: JTI_TTL)

    claims
  end

  def sso_user(claims)
    User.find_by(email: claims['sub'].to_s.downcase) || raise(::IdoitUp::Token::Error, "User '#{claims['sub']}' could not be found.")
  end
  # rubocop:enable Zammad/DetectTranslatableString

  def start_sso_session(user)
    session.delete(:switched_from_user_id)
    authentication_check_prerequesits(user, 'SSO')
    session[:persistent] = true
    session[:authentication_type] = 'SSO'
    user.activity_stream_log('session started', user.id, true)
  end

  # Only a real browser session counts (no API tokens, no "switch to user"
  # sessions). Device logging is skipped: it needs a fingerprint header that a
  # top-level navigation does not send.
  def browser_session_user
    return if session[:user_id].blank? || session[:switched_from_user_id].present?

    user = User.lookup(id: session[:user_id])
    user if user&.active
  end

  def safe_target(target)
    target.to_s.match?(TARGET_PATTERN) ? target : '#'
  end
end

# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'twitter_oauth'

class ExternalCredentialsTwitterController < ApplicationController
  before_action :authentication_check

  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    twitter_credential = ExternalCredential.find_by(name: 'Twitter')

    # TODO: refactor
    result = {
      #  consumer_key:    nil,
      #  consumer_secret: nil,
    }
    if !twitter_credential.nil?

      # p twitter_credential.credentials.inspect

      result[:consumer_key]    = twitter_credential.credentials[:consumer_key]
      result[:consumer_secret] = twitter_credential.credentials[:consumer_secret]
      result[:authorize_url] = twitter_credential.credentials[:authorize_url]
    end

    render json: result, status: :ok
  end

  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(ExternalCredential, params)
  end

  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    credentials = handle_credentials(params)

    # create object
    twitter_credential = ExternalCredential.new( name: 'Twitter', credentials: credentials )

    # save object
    twitter_credential.save!

    redirect_to credentials[:authorize_url]
  end

  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    credentials = handle_credentials(params)

    # find object
    twitter_credential = ExternalCredential.find(params[:id])

    # update object
    twitter_credential.update_attributes!( name: 'Twitter', credentials: credentials )

    redirect_to credentials.authorize_url
  end

  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(ExternalCredential, params)
  end

  def auth
    # https://zammad.tld/twitter_auth?oauth_token=uP15WgAAAAAAivjgAAABUSUkP5Y&oauth_verifier=OlKro1xj7gBQ5cwdvlcYQEniiEm1THsd
    params[:oauth_token]
    params[:oauth_verifier]

    params.require(:name, :oauth_token, :oauth_verifier)
    params.permit(:name, :oauth_token, :oauth_verifier)

    twitter_credential = ExternalCredential.find_by( name: 'Twitter' )

    if ( twitter_credential[:credentials][:oauth_token] != params[:oauth_token] )
      # TODO: ERROR
    end

    access_token = client.authorize(
      twitter_credential[:credentials][:oauth_token],
      twitter_credential[:credentials][:oauth_token_secret],
      oauth_verifier: params[:oauth_verifier]
    )

    credentials = {
      consumer_key:        twitter_credential[:credentials][:consumer_key],
      consumer_secret:     twitter_credential[:credentials][:consumer_secret],
      access_token:        access_token.token,
      access_token_secret: access_token.secret,
    }

    twitter_credential.update_attributes!(credentials: credentials )

    # TODO
    redirect_to "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#admin/path/external_credentials_twitter"
  end

  private

  def handle_credentials(params)

    params.require(:consumer_key)
    params.require(:consumer_secret)

    params.permit(:consumer_key, :consumer_secret)

    credentials = {
      consumer_key:    params[:consumer_key],
      consumer_secret: params[:consumer_secret],
    }

    client = TwitterOAuth::Client.new(
      consumer_key:    credentials[:consumer_key],
      consumer_secret: credentials[:consumer_secret],
    )

    # TODO: improve callback URL
    request_token = client.request_token(oauth_callback: "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#{Rails.configuration.api_path}/external_credentials_twitter/Twitter/auth")

    credentials[:oauth_token]        = request_token.token
    credentials[:oauth_token_secret] = request_token.secret
    credentials[:authorize_url]      = request_token.authorize_url

    credentials
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Authorization::Provider
  include Mixin::RequiredSubPaths

  attr_reader :auth_hash, :user, :info, :uid

  def initialize(auth_hash, user = nil)
    @auth_hash = auth_hash
    @uid = auth_hash['uid']
    @info = auth_hash['info'] || {}

    @user = user.presence || fetch_user
  end

  def name
    self.class.name.demodulize.underscore
  end

  private

  def fetch_user
    if Setting.get('auth_third_party_auto_link_at_inital_login')
      user = find_user
      return user if user.present?
    end

    if Setting.get('auth_third_party_no_create_user')
      account = uid || info['email']
      message = "User account '#{account}' not found for authentication provider '#{name.capitalize}'."
      Rails.logger.error { message }

      raise AccountError
    end

    User.create_from_hash!(auth_hash)
  end

  def find_user
    return if info['email'].nil?

    User.find_by(email: info['email'].downcase)
  end

  class AccountError < StandardError
    def initialize
      super(__('The user account does not exist. Please contact your administrator.'))
    end
  end
end

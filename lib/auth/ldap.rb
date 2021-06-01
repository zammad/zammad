# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'ldap'
require_dependency 'ldap/user'

class Auth
  class Ldap < Auth::Base

    def valid?(user, password)
      return false if !Setting.get('ldap_integration')

      ldap_user = ::Ldap::User.new()

      # get from config or fallback to login
      # for a list of user attributes which should
      # be used for logging in
      login_attributes = @config[:login_attributes] || %w[login]

      authed = login_attributes.any? do |attribute|
        ldap_user.valid?(user[attribute], password)
      end

      log_auth_result(user, authed)
      authed
    rescue => e
      message = "Can't connect to ldap backend #{e}"
      Rails.logger.info message
      Rails.logger.info e
      log(
        user:     user,
        status:   'failed',
        response: message,
      )
      false
    end

    private

    def log_auth_result(user, authed)
      result = authed ? 'success' : 'failed'
      log(
        user:   user,
        status: result,
      )
    end

    def log(user:, status:, response: nil)
      HttpLog.create(
        direction:     'out',
        facility:      'ldap',
        url:           "bind -> #{user.login}",
        status:        status,
        ip:            nil,
        request:       { content: user.login },
        response:      { content: response || status },
        method:        'tcp',
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::Signup < Service::Base

  attr_reader :user_data, :resend

  def initialize(user_data:, resend: false)
    super()

    @user_data = user_data
    @resend = resend
    @path = {
      signup: 'desktop/signup/verify/',
      taken:  'desktop/reset-password/verify/'
    }
  end

  def execute
    ensure_not_import_mode!

    Service::CheckFeatureEnabled.new(name: 'user_create_account').execute

    if resend
      user = ::User.find_by(email: user_data[:email].downcase)

      # The result is always positive to avoid leaking of existing user accounts.
      return true if !user || user.verified == true
    else
      PasswordPolicy.new(user_data[:password]).valid!

      return true if user_with_email_exists!

      user = create_user
    end

    result = ::User.signup_new_token(user)
    raise TokenGenerationError if !result || !result[:token]

    result[:url] = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#{@path[:signup]}#{result[:token].token}"

    NotificationFactory::Mailer.notification(
      template: 'signup',
      user:     user,
      objects:  result,
    )

    true
  end

  def ensure_not_import_mode!
    return if !Setting.get('import_mode')

    message = if resend
                __('Could not send user verification email because import_mode setting is on.')
              else
                __('Could not create user and send verification email because import_mode setting is on.')
              end

    Rails.logger.error message
    raise Exceptions::UnprocessableEntity, message
  end

  class TokenGenerationError < StandardError
    def initialize
      super(__('The token could not be generated.'))
    end
  end

  private

  def user_with_email_exists!
    existing_user = User.find_by(email: user_data[:email].downcase.strip)
    return false if existing_user.blank?

    result = User.password_reset_new_token(existing_user.email)
    result[:url] = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#{@path[:taken]}#{result[:token].token}"

    NotificationFactory::Mailer.notification(
      template: 'signup_taken_reset',
      user:     existing_user,
      objects:  result
    )

    true
  end

  def create_user
    user = User.new(user_data)

    user.role_ids = Role.signup_role_ids
    user.source = 'signup'
    user.skip_ensure_uniq_email = true
    user.validate!

    UserInfo.ensure_current_user_id do
      user.save!
    end

    user
  end
end

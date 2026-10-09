# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::Signup < Service::Base
  include Service::Concerns::HoldsResponseDeadline

  # Signup is unauthenticated, so only these attributes may ever be assigned. Anything
  # else - like `verified`, `login` or `organization_id` - would let an anonymous caller
  # bypass the email verification or join an arbitrary organization.
  PERMITTED_ATTRIBUTES = %i[firstname lastname email password].freeze

  attr_reader :user_data, :resend

  def initialize(user_data:, resend: false)
    @user_data = user_data
    @resend = resend
    @path = {
      signup: 'desktop/signup/verify/',
      taken:  'desktop/reset-password/verify/'
    }
  end

  def execute
    ensure_not_import_mode!

    Service::CheckFeatureEnabled.execute(name: 'user_create_account')

    return resend_verification_email if resend

    PasswordPolicy.new(user_data[:password]).valid!

    return true if user_with_email_exists!

    send_verification_email(create_user)
  end

  def ensure_not_import_mode!
    return if !Setting.get('import_mode')

    message = if resend
                __('Could not send user verification email because import_mode setting is on.')
              else
                __('Could not create user and send verification email because import_mode setting is on.')
              end

    Rails.logger.error message
    raise Exceptions::UnprocessableContent, message
  end

  class TokenGenerationError < StandardError
    def initialize
      super(__('The token could not be generated.'))
    end
  end

  private

  # Answers after a fixed duration, whatever the part below has to do.
  def resend_verification_email
    with_response_deadline do
      user = ::User.find_by(email: user_data[:email].downcase)

      # The result is always positive to avoid leaking of existing user accounts.
      next true if !user || user.verified == true

      send_verification_email(user)
    end
  end

  def send_verification_email(user)
    result = ::User.signup_new_token(user)
    raise TokenGenerationError if !result || !result[:token]

    # Delivered in the background, so that the request does not wait for the SMTP server.
    NotificationMailerJob.perform_later(
      template: 'signup',
      user:     user,
      objects:  result,
      url_path: @path[:signup],
    )

    true
  end

  def user_with_email_exists!
    existing_user = User.find_by(email: user_data[:email].downcase.strip)
    return false if existing_user.blank?

    result = User.password_reset_new_token(existing_user.email)

    NotificationMailerJob.perform_later(
      template: 'signup_taken_reset',
      user:     existing_user,
      objects:  result,
      url_path: @path[:taken],
    )

    true
  end

  def create_user
    user = User.new(user_data.symbolize_keys.slice(*PERMITTED_ATTRIBUTES))

    user.role_ids = Role.signup_role_ids
    user.source = 'signup'
    user.skip_ensure_uniq_email = true
    user.disable_name_guessing = true
    user.validate!

    UserInfo.ensure_current_user_id do
      user.save!
    end

    user
  end
end

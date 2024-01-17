# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::AddFirstAdmin < Service::Base

  def execute(user_data:, request:)

    if Service::System::CheckSetup.done?
      raise Service::System::CheckSetup::SystemSetupError, __('This system has already been configured and an administrator account exists.')
    end

    if user_data[:email].blank?
      raise Exceptions::MissingAttribute.new('email', __("The required attribute 'email' is missing."))
    end

    PasswordPolicy.new(user_data[:password]).valid!

    User.new(user_data).tap do |user|
      user.role_ids  = Role.where(name: %w[Admin Agent]).pluck(:id)
      user.group_ids = Group.pluck(:id)
      UserInfo.ensure_current_user_id { user.save! }
      configure_system(user:, request:)
    end
  end

  private

  def configure_system(user:, request:)
    Setting.set('system_init_done', true)
    Service::Image.organization_suggest(user.email) if user.email.present?
    Calendar.init_setup(request.remote_ip)
    begin
      TextModule.load(request.env['HTTP_ACCEPT_LANGUAGE'] || 'en-us')
    rescue => e
      logger.error "Unable to load text modules #{request.env['HTTP_ACCEPT_LANGUAGE'] || 'en-us'}: #{e.message}"
    end
  end
end

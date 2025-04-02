# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Authorization::Provider::Saml < Authorization::Provider
  private

  def find_user
    user = User.find_by(login: uid)

    if !user && !Setting.get('user_email_multiple_use') && info['email'].present?
      user = User.find_by(email: info['email'].downcase)
    end

    user
  end
end

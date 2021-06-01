# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Auth
  class Developer < Auth::Base

    def valid?(user, password)
      return false if user.blank?
      return false if Setting.get('developer_mode') != true
      return false if password != 'test'

      Rails.logger.info "System in developer mode, authentication for user #{user.login} ok."
      true
    end
  end
end

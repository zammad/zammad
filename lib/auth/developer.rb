# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Auth::Developer
  def self.check(username, password, _config, user)

    # development systems
    return false if !username
    return false if !user
    return false if Setting.get('developer_mode') != true
    return false if password != 'test'
    Rails.logger.info "System in developer mode, authentication for user #{user.login} ok."
    user
  end
end

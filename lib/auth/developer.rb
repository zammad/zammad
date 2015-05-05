# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module Auth::Developer
  def self.check( username, password, config, user )

    # development systems
    if Setting.get('developer_mode') == true
      if password == 'test'
        Rails.logger.info "System in developer mode, authentication for user #{user.login} ok."
        return user
      end
    end

    false
  end
end

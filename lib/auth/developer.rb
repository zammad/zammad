# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module Auth::Developer
  def self.check( username, password, config, user )

    # development systems
    if Setting.get('developer_mode') == true
      return user if password == 'test'
    end

    false
  end
end

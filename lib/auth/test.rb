# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module Auth::Test
  def self.check( username, password, config, user )

    # development systems
    if !ENV['RAILS_ENV'] || ENV['RAILS_ENV'] == 'development' || ENV['RAILS_ENV'] == 'test'
      return user if password == 'test'
    end

    return false
  end
end

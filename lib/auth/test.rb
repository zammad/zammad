module Auth
end
module Auth::TEST
  def self.check( username, password, config, user )

    # development systems
    if !ENV['RAILS_ENV'] || ENV['RAILS_ENV'] == 'development'
      return user if password == 'test'
    end
    
    return false
  end
end
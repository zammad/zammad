module Auth::TEST
  def self.check( user, username, password, config )

    # development systems
    if !ENV['RAILS_ENV'] || ENV['RAILS_ENV'] == 'development'
      return user if password == 'test'
    end
    
    return false
  end
end

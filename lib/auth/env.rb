module Auth
end
module Auth::ENV
  def self.check( user, username, password, config )

    # try to find user based on login
    if ENV['REMOTE_USER']
      user = User.where( :login => ENV['REMOTE_USER'], :active => true ).first
      return user if user
    end

    if ENV['HTTP_REMOTE_USER']
      user = User.where( :login => ENV['HTTP_REMOTE_USER'], :active => true ).first
      return user if user
    end

    return false
  end
end
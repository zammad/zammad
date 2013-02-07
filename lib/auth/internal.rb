module Auth
end
module Auth::INTERNAL
  def self.check( username, password, config, user )

    # return if no user exists
    return nil if !user

    # sha auth check
    if user.password =~ /^\{sha2\}/
      crypted = Digest::SHA2.hexdigest( password )
      return user if user.password == "{sha2}#{crypted}"
    end

    # plain auth check
    return user if user.password == password

    return false
  end
end
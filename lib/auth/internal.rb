# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Auth::Internal
  def self.check(username, password, _config, user)

    # return if no user exists
    return false if !username
    return false if !user

    # sha auth check
    if user.password =~ /^\{sha2\}/
      crypted = Digest::SHA2.hexdigest(password)
      return user if user.password == "{sha2}#{crypted}"
    end

    # plain auth check
    return user if user.password == password

    false
  end
end

# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Token < ActiveRecord::Base
  before_create           :generate_token

  belongs_to              :user

  def self.check( data )

    # fetch token
    token = Token.find_by( action: data[:action], name: data[:name] )
    return if !token

    # check if token is still valid
    if !token.persistent &&
       token.created_at < 1.day.ago

      # delete token
      token.delete
      token.save
      return
    end

    # return token if valid
    token.user
  end

  private

  def generate_token

    loop do
      self.name = SecureRandom.hex(20)

      break if !Token.exists?( name: self.name )
    end
  end
end

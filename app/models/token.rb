# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Token < ActiveRecord::Base
  before_create :generate_token
  belongs_to    :user

=begin

create new token

  token = Token.create(action: 'PasswordReset', user_id: user.id)

returns

  the token

create new persistent token

  token = Token.create(
    action:     'CalendarSubscriptions',
    persistent: true,
    user_id:    user.id,
  )

in case if you use it via an controller, e. g. you can verify via "curl -H "Authorization: Token token=33562a00d7eda2a7c2fb639b91c6bcb8422067b6" http://...

returns

  the token

=end

=begin

check token

  user = Token.check(action: 'PasswordReset', name: 'TheTokenItSelf')

returns

  user for who this token was created

=end

  def self.check(data)

    # fetch token
    token = Token.find_by(action: data[:action], name: data[:name])
    return if !token

    # check if token is still valid
    if !token.persistent &&
       token.created_at < 1.day.ago

      # delete token
      token.delete
      token.save
      return
    end

    # return token user
    token.user
  end

=begin

cleanup old token

  Token.cleanup

=end

  def self.cleanup
    Token.where('persistent IS ? AND created_at < ?', nil, Time.zone.now - 30.days).delete_all
    true
  end

  private

  def generate_token

    loop do
      self.name = SecureRandom.hex(30)
      break if !Token.exists?(name: name)
    end
  end
end

# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Token < ActiveRecord::Base
  before_create :generate_token
  belongs_to    :user
  store         :preferences

=begin

create new token

  token = Token.create(action: 'PasswordReset', user_id: user.id)

returns

  the token

create new persistent token

  token = Token.create(
    action:     'api',
    persistent: true,
    user_id:    user.id,
    preferences: {
      permission: {
        'user_preferences.calendar' => true,
      }
    }
  )

in case if you use it via an controller, e. g. you can verify via "curl -H "Authorization: Token token=33562a00d7eda2a7c2fb639b91c6bcb8422067b6" http://...

returns

  the token

=end

=begin

check token

  user = Token.check(action: 'PasswordReset', name: 'TheTokenItSelf')

check api token with permissions

  user = Token.check(action: 'api', name: 'TheTokenItSelf', permission: 'admin.session')

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

    user = token.user

    # persistent token not valid if user is inative
    if !data[:inactive_user]
      return if token.persistent && user.active == false
    end

    # add permission check
    if data[:permission]
      return if !user.permissions?(data[:permission])
      return if !token.preferences[:permission]
      return if token.preferences[:permission][data[:permission]] != true
    end

    # return token user
    user
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
      self.name = SecureRandom.urlsafe_base64(48)
      break if !Token.exists?(name: name)
    end
  end
end

# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Token < ApplicationModel
  before_create :generate_token
  belongs_to    :user, optional: true
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

  user = Token.check(action: 'PasswordReset', name: '123abc12qweads')

check api token with permissions

  user = Token.check(action: 'api', name: '123abc12qweads', permission: 'admin.session')

  user = Token.check(action: 'api', name: '123abc12qweads', permission: ['admin.session', 'ticket.agent'])

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

    # persistent token not valid if user is inactive
    if !data[:inactive_user]
      return if token.persistent && user.active == false
    end

    # add permission check
    if data[:permission]
      return if !user.permissions?(data[:permission])
      return if !token.preferences[:permission]

      local_permissions = data[:permission]
      if data[:permission].class != Array
        local_permissions = [data[:permission]]
      end
      match = false
      local_permissions.each do |local_permission|
        local_permissions = Permission.with_parents(local_permission)
        local_permissions.each do |local_permission_name|
          next if !token.preferences[:permission].include?(local_permission_name)

          match = true
          break
        end
        next if !match

        break
      end
      return if !match
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
    true
  end
end

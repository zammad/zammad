# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Token < ApplicationModel
  include CanBeAuthorized

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
    return if !data[:inactive_user] && token.persistent && user.active == false

    # add permission check
    return if data[:permission] && !token.permissions?(data[:permission])

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

  def permissions
    Permission.where(
      name:   Array(preferences[:permission]),
      active: true,
    )
  end

  def permissions?(names)
    return false if !effective_user.permissions?(names)

    super(names)
  end

  # allows to evaluate token permissions in context of given user instead of owner
  # @param [User] user to use as context for the given block
  # @param block to evaluate in given context
  def with_context(user:, &block)
    @effective_user = user

    instance_eval(&block) if block
  ensure
    @effective_user = nil
  end

  private

  def generate_token
    loop do
      self.name = SecureRandom.urlsafe_base64(48)
      break if !Token.exists?(name: name)
    end
    true
  end

  # token owner or user set by #with_context
  def effective_user
    @effective_user || user
  end
end

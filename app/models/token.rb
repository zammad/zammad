# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

    return token.user if token.check?(data)
  end

  # Check token instance validity
  # Invalid non-persistant instance is removed
  #
  # @param data [Hash] check options
  # @option data [Boolean] :inactive_user skip checking if referenced user is active
  # @option data [String, Array<String>] :permission check if token has given permissions
  #
  # @return [Boolean]

  def check?(data = {})
    if !persistent && created_at < 1.day.ago
      destroy
      return false
    end

    # persistent token not valid if user is inactive
    return false if !data[:inactive_user] && persistent && user.active == false

    # add permission check
    return false if data[:permission] && !permissions?(data[:permission])

    true
  end

=begin

cleanup old token

  Token.cleanup

=end

  def self.cleanup
    Token.where('persistent IS ? AND created_at < ?', nil, 30.days.ago).delete_all
    true
  end

  def permissions
    Permission.where(
      name:   Array(preferences[:permission]),
      active: true,
    )
  end

  def permissions?(permissions)
    permissions!(permissions)
    true
  rescue Exceptions::Forbidden
    false
  end

  def permissions!(auth_query)
    return true if effective_user.permissions?(auth_query) && Auth::RequestCache.permissions?(self, auth_query)

    raise Exceptions::Forbidden, __('Not authorized (token)!')
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

  # fetch token for a user with a given action
  # checks token validity
  #
  # @param [String] action name
  # @param [Integer, User] user
  #
  # @return [Token, nil]
  def self.fetch(action_name, user_id = UserInfo.current_user_id)
    token = where(action: action_name, user_id: user_id).first

    return token if token&.check?
  end

  # creates or returns existing token
  #
  # @param [String] action name
  # @param [Integer, User] user
  #
  # @return [String]
  def self.ensure_token!(action_name, user_id = UserInfo.current_user_id, persistent: false)
    instance = fetch(action_name, user_id)

    return instance.name if instance.present?

    create!(action: action_name, user_id: user_id, persistent: persistent).name
  end

  # regenerates an existing token
  #
  # @param [String] action name
  # @param [Integer, User] user
  #
  # @return [String]
  def self.renew_token!(action_name, user_id = UserInfo.current_user_id, persistent: false)
    instance = fetch(action_name, user_id)

    return create(action: action_name, user_id: user_id, persistent: persistent).name if !instance

    instance.renew_token!
  end

  # regenerates an existing token
  #
  # @return [String]
  def renew_token!
    generate_token
    save!

    name
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

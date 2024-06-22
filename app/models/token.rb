# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Token < ApplicationModel
  include Token::Permissions
  include Token::TriggersSubscriptions

  before_create :generate_token
  belongs_to    :user, optional: true
  store         :preferences

  scope :without_sensitive_columns, -> { select(column_names - %w[persistent token]) }

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

in case if you use it via an controller, e. g. you can verify via "curl -H "Authorization: Token token=my_token" http://...

returns

  the token

=end

=begin

check token

  user = Token.check(action: 'PasswordReset', token: '123abc12qweads')

check api token with permissions

  user = Token.check(action: 'api', token: '123abc12qweads', permission: 'admin.session')

  user = Token.check(action: 'api', token: '123abc12qweads', permission: ['admin.session', 'ticket.agent'])

returns

  user for who this token was created

=end

  def self.check(action:, token:, permission: nil, inactive_user: false)
    # fetch token
    token = Token.find_by(action:, token:)

    return if !token

    token.user if token.check?(permission:, inactive_user:)
  end

  # Check token instance validity
  # Invalid non-persistant instance is removed
  #
  # @param data [Hash] check options
  # @option data [Boolean] :inactive_user skip checking if referenced user is active
  # @option data [String, Array<String>] :permission check if token has given permissions
  #
  # @return [Boolean]

  def check?(permission: nil, inactive_user: false)
    if !persistent && created_at < 1.day.ago
      destroy
      return false
    end

    # persistent token not valid if user is inactive
    return false if !inactive_user && persistent && user.active == false

    # add permission check
    return false if permission && !permissions?(permission)

    true
  end

=begin

cleanup old token

  Token.cleanup

=end

  def self.cleanup
    Token.where(persistent: false, created_at: ...30.days.ago).delete_all

    true
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
  def self.fetch(action, user_id = UserInfo.current_user_id)
    token = find_by(action: action, user_id: user_id)

    token if token&.check?
  end

  # creates or returns existing token
  #
  # @param [String] action name
  # @param [Integer, User] user
  #
  # @return [String]
  def self.ensure_token!(action, user_id = UserInfo.current_user_id, persistent: false)
    instance = fetch(action, user_id)

    return instance.token if instance.present?

    create!(action: action, user_id: user_id, persistent: persistent).token
  end

  # regenerates an existing token
  #
  # @param [String] action name
  # @param [Integer, User] user
  #
  # @return [String]
  def self.renew_token!(action, user_id = UserInfo.current_user_id, persistent: false)
    instance = fetch(action, user_id)

    return create(action: action, user_id: user_id, persistent: persistent).token if !instance

    instance.renew_token!
  end

  # regenerates an existing token
  #
  # @return [String]
  def renew_token!
    generate_token
    save!

    token
  end

  def visible_in_frontend?
    action == 'api' && persistent
  end

  private

  def generate_token
    loop do
      self.token = SecureRandom.urlsafe_base64(48)
      break if !Token.exists?(token: token)
    end
    true
  end

  # token owner or user set by #with_context
  def effective_user
    @effective_user || user
  end
end

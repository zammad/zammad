# encoding: utf-8
require 'test_helper'

class TokenTest < ActiveSupport::TestCase
  test 'token' do

    groups = Group.all
    roles  = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'token-agent1@example.com',
      firstname: 'Token',
      lastname: 'Agent1',
      email: 'token-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # invalid token
    user = Token.check(
      action: 'PasswordReset',
      name: '1NV4L1D',
    )
    assert_not(user)

    # generate fresh token
    token = Token.create(
      action: 'PasswordReset',
      user_id: agent1.id,
    )
    assert(token)
    assert_nil(token.persistent)
    user = Token.check(
      action: 'PasswordReset_NotExisting',
      name: token.name,
    )
    assert_not(user)
    user = Token.check(
      action: 'PasswordReset',
      name: token.name,
    )
    assert(user)
    assert_equal('Token', user.firstname)
    assert_equal('Agent1', user.lastname)
    assert_equal('token-agent1@example.com', user.email)

    # two days but not persistent
    token = Token.create(
      action: 'PasswordReset',
      user_id: agent1.id,
      created_at: 2.days.ago,
      persistent: false,
    )
    user = Token.check(
      action: 'PasswordReset',
      name: token.name,
    )
    assert_not(user)

    # two days but persistent
    token = Token.create(
      action: 'iCal',
      user_id: agent1.id,
      created_at: 2.days.ago,
      persistent: true,
    )
    user = Token.check(
      action: 'iCal',
      name: token.name,
    )
    assert(user)
    assert_equal('Token', user.firstname)
    assert_equal('Agent1', user.lastname)
    assert_equal('token-agent1@example.com', user.email)

    # api token with permissions
    token = Token.create(
      action:      'api',
      label:       'some label',
      persistent:  true,
      user_id:     agent1.id,
      preferences: {
        permission: ['admin', 'ticket.agent'], # agent has no access to admin.*
      }
    )
    user = Token.check(
      action: 'api',
      name: token.name,
      permission: 'admin.session',
    )
    assert_not(user)
    user = Token.check(
      action: 'api',
      name: token.name,
      permission: 'admin',
    )
    assert_not(user)
    user = Token.check(
      action: 'api',
      name: token.name,
      permission: 'ticket',
    )
    assert_not(user)
    user = Token.check(
      action: 'api',
      name: token.name,
      permission: 'ticket.agent.sub',
    )
    assert(user)
    user = Token.check(
      action: 'api',
      name: token.name,
      permission: 'admin_not_extisting',
    )
    assert_not(user)
    user = Token.check(
      action: 'api',
      name: token.name,
      permission: 'ticket.agent',
    )
    assert(user)
    assert_equal('Token', user.firstname)
    assert_equal('Agent1', user.lastname)
    assert_equal('token-agent1@example.com', user.email)

    user = Token.check(
      action: 'api',
      name: token.name,
      permission: ['ticket.agent', 'not_existing'],
    )
    assert(user)
    assert_equal('Token', user.firstname)
    assert_equal('Agent1', user.lastname)
    assert_equal('token-agent1@example.com', user.email)

  end

end

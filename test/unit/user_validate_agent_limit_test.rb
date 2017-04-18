# encoding: utf-8
require 'test_helper'

class UserValidateAgentLimit < ActiveSupport::TestCase
  test 'user_validate_agent_limit' do

    users = User.of_role('Agent')
    UserInfo.current_user_id = 1
    Setting.set('system_agent_limit', users.count + 2)
    role_agent = Role.lookup(name: 'Agent')
    role_customer = Role.lookup(name: 'Customer')

    user1 = User.create(
      firstname:   'Firstname',
      lastname:    'Lastname',
      email:       'some@example.com',
      login:       'some-agentlimit@example.com',
      roles:       [role_agent],
    )
    user2 = User.create(
      firstname:   'Firstname1',
      lastname:    'Lastname1',
      email:       'some-agentlimit-1@example.com',
      login:       'some-agentlimit-1@example.com',
      roles:       [role_agent],
    )

    assert_raises(Exceptions::UnprocessableEntity) {
      user3 = User.create(
        firstname: 'Firstname2',
        lastname:  'Lastname2',
        email:     'some-agentlimit-2@example.com',
        login:     'some-agentlimit-2@example.com',
        roles:     [role_agent],
      )
    }

    user3 = User.create(
      firstname: 'Firstname2',
      lastname:  'Lastname2',
      email:     'some-agentlimit-2@example.com',
      login:     'some-agentlimit-2@example.com',
      roles:     [role_customer],
    )

    assert_raises(Exceptions::UnprocessableEntity) {
      user3.roles = [role_agent]
    }

    user1.destroy
    user2.destroy
    user3.destroy
    Setting.set('system_agent_limit', nil)
  end
end

# encoding: utf-8
require 'test_helper'

class RoleValidateAgentLimit < ActiveSupport::TestCase
  test 'role_validate_agent_limit' do

    users = User.of_role('Agent')
    UserInfo.current_user_id = 1
    Setting.set('system_agent_limit', users.count + 2)

    permission_ticket_agent = Permission.where(name: 'ticket.agent')

    role_agent_limit_success = Role.create(
      name: 'agent-limit-test-success',
      note: 'agent-limit-test-success Role.',
      permissions: [],
      updated_by_id: 1,
      created_by_id: 1
    )
    role_agent_limit_fail = Role.create(
      name: 'agent-limit-test-fail',
      note: 'agent-limit-test-fail Role.',
      permissions: [],
      updated_by_id: 1,
      created_by_id: 1
    )

    user1 = User.create(
      firstname:   'Firstname',
      lastname:    'Lastname',
      email:       'some@example.com',
      login:       'some-agentlimit@example.com',
      roles:       [role_agent_limit_success],
    )
    user2 = User.create(
      firstname:   'Firstname1',
      lastname:    'Lastname1',
      email:       'some-agentlimit-1@example.com',
      login:       'some-agentlimit-1@example.com',
      roles:       [role_agent_limit_success],
    )
    user3 = User.create(
      firstname: 'Firstname2',
      lastname:  'Lastname2',
      email:     'some-agentlimit-2@example.com',
      login:     'some-agentlimit-2@example.com',
      roles:     [role_agent_limit_fail],
    )

    role_agent_limit_success.permissions = permission_ticket_agent
    assert_raises(Exceptions::UnprocessableEntity) {
      role_agent_limit_fail.permissions = permission_ticket_agent
    }

    user1.destroy
    user2.destroy
    user3.destroy
    role_agent_limit_success.destroy
    role_agent_limit_fail.destroy
    Setting.set('system_agent_limit', nil)
  end
end

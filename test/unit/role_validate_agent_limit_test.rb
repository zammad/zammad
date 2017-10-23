# encoding: utf-8
require 'test_helper'

class RoleValidateAgentLimit < ActiveSupport::TestCase
  test 'role_validate_agent_limit' do

    agent_max = User.with_permissions('ticket.agent').count
    UserInfo.current_user_id = 1
    Setting.set('system_agent_limit', agent_max + 2)

    permission_ticket_agent = Permission.where(name: 'ticket.agent')

    role_agent_limit_success = Role.create!(
      name: 'agent-limit-test-success',
      note: 'agent-limit-test-success Role.',
      permissions: [],
      active: true,
    )
    role_agent_limit_fail = Role.create!(
      name: 'agent-limit-test-fail',
      note: 'agent-limit-test-fail Role.',
      permissions: [],
      active: true,
    )

    user1 = User.create!(
      firstname: 'Firstname',
      lastname:  'Lastname',
      email:     'some-agentlimit-role@example.com',
      login:     'some-agentlimit-role@example.com',
      roles:     [role_agent_limit_success],
      active:    true,
    )
    user2 = User.create!(
      firstname: 'Firstname1',
      lastname:  'Lastname1',
      email:     'some-agentlimit-role-1@example.com',
      login:     'some-agentlimit-role-1@example.com',
      roles:     [role_agent_limit_success],
      active:    true,
    )
    user3 = User.create!(
      firstname: 'Firstname2',
      lastname:  'Lastname2',
      email:     'some-agentlimit-role-2@example.com',
      login:     'some-agentlimit-role-2@example.com',
      roles:     [role_agent_limit_fail],
      active:    true,
    )

    role_agent_limit_success.permissions = permission_ticket_agent
    assert_raises(Exceptions::UnprocessableEntity) do
      role_agent_limit_fail.permissions = permission_ticket_agent
    end

    role_agent_limit_fail.active = false
    role_agent_limit_fail.save!

    role_agent_limit_fail.permissions = permission_ticket_agent

    assert_raises(Exceptions::UnprocessableEntity) do
      role_agent_limit_fail.active = true
      role_agent_limit_fail.save!
    end

    user1.destroy!
    user2.destroy!
    user3.destroy!
    role_agent_limit_success.destroy!
    role_agent_limit_fail.destroy!
    Setting.set('system_agent_limit', nil)
  end
end

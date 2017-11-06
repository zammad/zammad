# encoding: utf-8
require 'test_helper'

class UserValidateAgentLimit < ActiveSupport::TestCase
  test 'user_validate_agent_limit' do

    UserInfo.current_user_id = 1
    agent_max = User.with_permissions('ticket.agent').count + 2
    Setting.set('system_agent_limit', agent_max)
    role_agent = Role.lookup(name: 'Agent')
    role_customer = Role.lookup(name: 'Customer')

    user1 = User.create!(
      firstname: 'Firstname',
      lastname:  'Lastname',
      email:     'some-agentlimit-user@example.com',
      login:     'some-agentlimit-user@example.com',
      roles:     [role_agent],
      active:    true,
    )
    user2 = User.create!(
      firstname: 'Firstname1',
      lastname:  'Lastname1',
      email:     'some-agentlimit-user-1@example.com',
      login:     'some-agentlimit-user-1@example.com',
      roles:     [role_agent],
      active:    true,
    )

    assert_raises(Exceptions::UnprocessableEntity) do
      user3 = User.create!(
        firstname: 'Firstname2',
        lastname:  'Lastname2',
        email:     'some-agentlimit-user-2@example.com',
        login:     'some-agentlimit-user-2@example.com',
        roles:     [role_agent],
        active:    true,
      )
    end

    user3 = User.create!(
      firstname: 'Firstname2',
      lastname:  'Lastname2',
      email:     'some-agentlimit-user-2@example.com',
      login:     'some-agentlimit-user-2@example.com',
      roles:     [role_customer],
      active:    true,
    )

    assert_raises(Exceptions::UnprocessableEntity) do
      user3.roles = [role_agent]
    end

    assert_equal(User.with_permissions('ticket.agent').count, agent_max)

    Setting.set('system_agent_limit', agent_max + 1)
    user3.reload
    user3.roles = [role_agent]
    user3.save!

    user3.active = false
    user3.save!

    Setting.set('system_agent_limit', agent_max)

    # try to activate inactive agent again
    assert_raises(Exceptions::UnprocessableEntity) do
      user3 = User.find(user3.id)
      user3.active = true
      user3.save!
    end

    assert_equal(User.with_permissions('ticket.agent').count, agent_max)

    # try to activate inactive role again
    role_agent_limit = Role.create!(
      name: 'agent-limit-test-invalid-role',
      note: 'agent-limit-test-invalid-role Role.',
      permissions: Permission.where(name: 'ticket.agent'),
      active: false,
    )
    user3.roles = [role_agent_limit]
    user3.active = true
    user3.save!

    assert_raises(Exceptions::UnprocessableEntity) do
      role_agent_limit.active = true
      role_agent_limit.save!
    end

    assert_equal(User.with_permissions('ticket.agent').count, agent_max)

    # set roles of agent again
    role_admin = Role.lookup(name: 'Admin')
    user2.roles = [role_agent, role_admin]
    user2.save!

    user2.role_ids = [role_admin.id, role_agent_limit.id]
    user2.save!

    user2.role_ids = [role_admin.id.to_s, role_agent_limit.id.to_s]
    user2.save!

    user1.destroy!
    user2.destroy!
    user3.destroy!
    role_agent_limit.destroy!
    Setting.set('system_agent_limit', nil)
  end
end

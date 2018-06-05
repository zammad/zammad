require 'test_helper'

class UserGroupTest < ActiveSupport::TestCase
  test 'user group permissions' do
    rand = rand(9_999_999_999)
    agent1 = User.create!(
      login: "agent-permission-check#{rand}@example.com",
      firstname: 'vaild_agent_group_permission-1',
      lastname: 'Agent',
      email: "agent-permission-check#{rand}@example.com",
      password: 'agentpw',
      active: true,
      roles: Role.where(name: 'Agent'),
      groups: Group.all,
      updated_by_id: 1,
      created_by_id: 1,
    )

    group1 = Group.create!(
      name: "GroupPermissionsTest-#{rand(9_999_999_999)}",
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_nothing_raised do
      UserGroup.create!(user: agent1, group: group1, access: 'full')
    end

    assert_raises do
      UserGroup.create!(user: agent1, group: group1, access: 'read')
    end

    UserGroup.where(user: agent1, group: group1).destroy_all

    assert_nothing_raised do
      UserGroup.create!(user: agent1, group: group1, access: 'read')
    end

    assert_raises do
      UserGroup.create!(user: agent1, group: group1, access: 'full')
    end
  end
end

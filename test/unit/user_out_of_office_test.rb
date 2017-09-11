require 'test_helper'

class UserOutOfOfficeTest < ActiveSupport::TestCase
  setup do

    UserInfo.current_user_id = 1

    groups = Group.all
    roles = Role.where(name: 'Agent')
    @agent1 = User.create_or_update(
      login: 'user-out_of_office-agent1@example.com',
      firstname: 'UserOutOfOffice',
      lastname: 'Agent1',
      email: 'user-out_of_office-agent1@example.com',
      password: 'agentpw',
      active: true,
      out_of_office: false,
      roles: roles,
      groups: groups,
    )
    @agent2 = User.create_or_update(
      login: 'user-out_of_office-agent2@example.com',
      firstname: 'UserOutOfOffice',
      lastname: 'Agent2',
      email: 'user-out_of_office-agent2@example.com',
      password: 'agentpw',
      active: true,
      out_of_office: false,
      roles: roles,
      groups: groups,
    )
    @agent3 = User.create_or_update(
      login: 'user-out_of_office-agent3@example.com',
      firstname: 'UserOutOfOffice',
      lastname: 'Agent3',
      email: 'user-out_of_office-agent3@example.com',
      password: 'agentpw',
      active: true,
      out_of_office: false,
      roles: roles,
      groups: groups,
    )
  end

  test 'check out_of_office?' do

    # check
    assert_not(@agent1.out_of_office?)
    assert_not(@agent2.out_of_office?)
    assert_not(@agent3.out_of_office?)

    assert_raises(Exceptions::UnprocessableEntity) {
      @agent1.out_of_office = true
      @agent1.out_of_office_start_at = Time.zone.now + 2.days
      @agent1.out_of_office_end_at = Time.zone.now
      @agent1.save!
    }

    assert_raises(Exceptions::UnprocessableEntity) {
      @agent1.out_of_office = true
      @agent1.out_of_office_start_at = Time.zone.now
      @agent1.out_of_office_end_at = Time.zone.now - 2.days
      @agent1.save!
    }

    assert_raises(Exceptions::UnprocessableEntity) {
      @agent1.out_of_office = true
      @agent1.out_of_office_start_at = nil
      @agent1.out_of_office_end_at = Time.zone.now
      @agent1.save!
    }

    assert_raises(Exceptions::UnprocessableEntity) {
      @agent1.out_of_office = true
      @agent1.out_of_office_start_at = Time.zone.now
      @agent1.out_of_office_end_at = nil
      @agent1.save!
    }

    @agent1.out_of_office = false
    @agent1.out_of_office_start_at = Time.zone.now + 2.days
    @agent1.out_of_office_end_at = Time.zone.now
    @agent1.save!

    assert_not(@agent1.out_of_office?)

    assert_raises(Exceptions::UnprocessableEntity) {
      @agent1.out_of_office = true
      @agent1.out_of_office_start_at = Time.zone.now + 2.days
      @agent1.out_of_office_end_at = Time.zone.now + 4.days
      @agent1.save!
    }
    assert_raises(Exceptions::UnprocessableEntity) {
      @agent1.out_of_office_replacement_id = 999_999_999_999 # not existing
      @agent1.save!
    }
    @agent1.out_of_office_replacement_id = @agent2.id
    @agent1.save!

    assert_not(@agent1.out_of_office?)

    travel 2.days

    assert(@agent1.out_of_office?)
    assert(@agent1.out_of_office_agent_of.blank?)
    assert_equal(1, @agent2.out_of_office_agent_of.count)
    assert_equal(@agent1.id, @agent2.out_of_office_agent_of[0].id)

    travel 1.day

    assert(@agent1.out_of_office?)

    travel 1.day

    assert(@agent1.out_of_office?)

    travel 1.day

    assert_not(@agent1.out_of_office?)

    assert_not(@agent1.out_of_office_agent)

    assert_not(@agent2.out_of_office_agent)

    assert_equal(0, @agent1.out_of_office_agent_of.count)
    assert_equal(0, @agent2.out_of_office_agent_of.count)

    @agent2.out_of_office = true
    @agent2.out_of_office_start_at = Time.zone.now
    @agent2.out_of_office_end_at = Time.zone.now + 4.days
    @agent2.out_of_office_replacement_id = @agent3.id
    @agent2.save!

    assert(@agent2.out_of_office?)

    assert_equal(@agent2.out_of_office_agent.id, @agent3.id)

    assert_equal(0, @agent1.out_of_office_agent_of.count)
    assert_equal(0, @agent2.out_of_office_agent_of.count)
    assert_equal(1, @agent3.out_of_office_agent_of.count)
    assert_equal(@agent2.id, @agent3.out_of_office_agent_of[0].id)

    travel 4.days

    assert_equal(0, @agent1.out_of_office_agent_of.count)
    assert_equal(0, @agent2.out_of_office_agent_of.count)
    assert_equal(1, @agent3.out_of_office_agent_of.count)
    assert_equal(@agent2.id, @agent3.out_of_office_agent_of[0].id)

    travel 1.day

    assert_equal(0, @agent1.out_of_office_agent_of.count)
    assert_equal(0, @agent2.out_of_office_agent_of.count)
    assert_equal(0, @agent3.out_of_office_agent_of.count)
  end

end

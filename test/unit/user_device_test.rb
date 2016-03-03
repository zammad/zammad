require 'test_helper'

class UserDeviceTest < ActiveSupport::TestCase
  setup do

    # create agent
    groups = Group.all
    roles = Role.where( name: 'Agent' )

    UserInfo.current_user_id = 1

    @agent = User.create_or_update(
      login: 'user-device-agent@example.com',
      firstname: 'UserDevice',
      lastname: 'Agent',
      email: 'user-device-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )
  end

  test 'aaa - session test' do

    # signin with fingerprint A from country A via session -> new device #1
    user_device1 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '91.115.248.231',
      @agent.id,
      'fingerprint1234',
      'session',
    )

    # signin with fingerprint A from country B via session -> new device #2
    user_device2 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '176.198.137.254',
      @agent.id,
      'fingerprint1234',
      'session',
    )
    assert_not_equal(user_device1.id, user_device2.id)

    # signin with fingerprint B from country A via session -> new device #3
    user_device3 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '91.115.248.231',
      @agent.id,
      'fingerprintABC',
      'session',
    )
    assert_not_equal(user_device2.id, user_device3.id)

    # signin with fingerprint A from country A via session -> new device #1
    user_device4 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '91.115.248.231',
      @agent.id,
      'fingerprint1234',
      'session',
    )
    assert_equal(user_device1.id, user_device4.id)

    # signin with fingerprint A from country B via session -> new device #2
    user_device5 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '176.198.137.254',
      @agent.id,
      'fingerprint1234',
      'session',
    )
    assert_equal(user_device2.id, user_device5.id)

    # signin with fingerprint B from country A via session -> new device #3
    user_device6 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '91.115.248.231',
      @agent.id,
      'fingerprintABC',
      'session',
    )
    assert_equal(user_device3.id, user_device6.id)

  end

  test 'bbb - session test - user agent (unknown)' do

    # known user agent
    user_device1 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '91.115.248.231',
      @agent.id,
      nil,
      'session',
    )
    assert_equal('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36', user_device1.user_agent)
    assert_equal('Mac, Chrome', user_device1.name)

    # unknown user agent
    user_device2 = UserDevice.add(
      'ABC 123',
      '91.115.248.231',
      @agent.id,
      nil,
      'session',
    )
    assert_equal('ABC 123', user_device2.user_agent)
    assert_equal('ABC 123', user_device2.browser)
    assert_equal('ABC 123', user_device2.name)

    # partently known
    user_device3 = UserDevice.add(
      'Mozilla/5.0 (iPhone; CPU iPhone OS 8_4 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12H143 Safari/600.1.4',
      '91.115.248.231',
      @agent.id,
      nil,
      'session',
    )
    assert_equal('Mozilla/5.0 (iPhone; CPU iPhone OS 8_4 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12H143 Safari/600.1.4', user_device3.user_agent)
    assert_equal('Safari', user_device3.browser)
    assert_equal('Ios, Safari', user_device3.name)

    user_device4 = UserDevice.add(
      'Mac+OS+X/10.10.5 (14F27) CalendarAgent/316.1',
      '91.115.248.231',
      @agent.id,
      nil,
      'session',
    )
    assert_equal('Mac+OS+X/10.10.5 (14F27) CalendarAgent/316.1', user_device4.user_agent)
    assert_equal('Mac+OS+X/10.10.5 (14F27) CalendarAgent/316.1', user_device4.browser)
    assert_equal('Mac, Mac+OS+X/10.10.5 (14F27) CalendarAgent/316.1', user_device4.name)

  end

  test 'ccc - api test' do

    # signin with ua from country A via basic auth -> new device #1
    user_device1 = UserDevice.add(
      'curl/7.43.0',
      '91.115.248.231',
      @agent.id,
      nil,
      'basic_auth',
    )

    # signin with ua from country B via basic auth -> new device #2
    user_device2 = UserDevice.add(
      'curl/7.43.0',
      '176.198.137.254',
      @agent.id,
      nil,
      'basic_auth',
    )
    assert_not_equal(user_device1.id, user_device2.id)

    # signin with ua from country A via basic auth -> new device #1
    user_device3 = UserDevice.add(
      'curl/7.43.0',
      '91.115.248.231',
      @agent.id,
      nil,
      'basic_auth',
    )
    assert_equal(user_device1.id, user_device3.id)

    # signin with ua from country B via basic auth -> new device #2
    user_device4 = UserDevice.add(
      'curl/7.43.0',
      '176.198.137.254',
      @agent.id,
      nil,
      'basic_auth',
    )
    assert_equal(user_device2.id, user_device4.id)

    # signin with ua from country A via token auth -> new device #1
    user_device5 = UserDevice.add(
      'curl/7.43.0',
      '91.115.248.231',
      @agent.id,
      nil,
      'token_auth',
    )
    assert_equal(user_device1.id, user_device5.id)

    # signin with ua from country B via token auth -> new device #2
    user_device6 = UserDevice.add(
      'curl/7.43.0',
      '176.198.137.254',
      @agent.id,
      nil,
      'token_auth',
    )
    assert_equal(user_device2.id, user_device6.id)

  end

end

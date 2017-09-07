require 'test_helper'

class UserDeviceTest < ActiveSupport::TestCase
  setup do

    UserInfo.current_user_id = 1

    groups = Group.all
    roles = Role.where(name: 'Agent')
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

    roles = Role.where(name: 'Customer')
    @customer = User.create_or_update(
      login: 'user-device-customer@example.com',
      firstname: 'UserDevice',
      lastname: 'Customer',
      email: 'user-device-customer@example.com',
      password: 'customerpw',
      active: true,
      roles: roles,
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

    # signin without ua from country A via basic auth -> new device #3
    user_device7 = UserDevice.add(
      '',
      '91.115.248.231',
      @agent.id,
      nil,
      'basic_auth',
    )
    assert_not_equal(user_device6.id, user_device7.id)

    user_device8 = UserDevice.add(
      '',
      '91.115.248.231',
      @agent.id,
      nil,
      'basic_auth',
    )
    assert_equal(user_device7.id, user_device8.id)

    user_device9 = UserDevice.add(
      nil,
      '91.115.248.231',
      @agent.id,
      nil,
      'basic_auth',
    )
    assert_equal(user_device8.id, user_device9.id)

    user_device10 = UserDevice.add(
      nil,
      '176.198.137.254',
      @agent.id,
      nil,
      'basic_auth',
    )
    assert_not_equal(user_device9.id, user_device10.id)
  end

  test 'ddd - api test' do

    # signin with fingerprint A from country A via session -> new device #1
    user_device1 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '91.115.248.231',
      @agent.id,
      'fingerprint1234',
      'session',
    )

    # action with same fingerprint -> same device
    user_device1_1 = UserDevice.action(
      user_device1.id,
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '91.115.248.231',
      @agent.id,
      'session',
    )
    assert_equal(user_device1.id, user_device1_1.id)

    # signin with same fingerprint -> same device
    user_device1_2 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '91.115.248.231',
      @agent.id,
      'fingerprint1234',
      'session',
    )
    assert_equal(user_device1.id, user_device1_2.id)

    # action with different fingerprint -> new device
    user_device1_3 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '91.115.248.231',
      @agent.id,
      'fingerprintABC',
      'session',
    )
    assert_not_equal(user_device1.id, user_device1_3.id)

    # signin with without accessable location -> new device
    user_device1_4 = UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      'not_existing_ip',
      @agent.id,
      'fingerprintABC',
      'session',
    )
    assert_not_equal(user_device1.id, user_device1_4.id)

    # action with fingerprint A from country B via session -> new device #2
    user_device2 = UserDevice.action(
      user_device1.id,
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '176.198.137.254',
      @agent.id,
      'session',
    )
    assert_not_equal(user_device1.id, user_device2.id)

    # action with fingerprint A without accessable location -> use current device #2
    user_device3 = UserDevice.action(
      user_device2.id,
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      'not_existing_ip',
      @agent.id,
      'session',
    )
    assert_equal(user_device2.id, user_device3.id)

  end

end

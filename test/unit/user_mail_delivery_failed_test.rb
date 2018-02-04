require 'test_helper'

class UserMailDeliveryFailedTest < ActiveSupport::TestCase
  setup do

    UserInfo.current_user_id = 1

    roles = Role.where(name: 'Customer')
    @customer1 = User.create_or_update(
      login: 'user-mail-delivery-failed-customer1@example.com',
      firstname: 'UserOutOfOffice',
      lastname: 'Customer1',
      email: 'user-mail-delivery-failed-customer1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
    )

  end

  test 'check reset of mail_delivery_failed' do

    @customer1.preferences[:mail_delivery_failed] = true
    @customer1.preferences[:mail_delivery_failed_data] = Time.zone.now
    @customer1.save!
    @customer1.reload

    assert_equal(@customer1.preferences[:mail_delivery_failed], true)
    assert(@customer1.preferences[:mail_delivery_failed_data])

    @customer1.email = 'new-user-mail-delivery-failed-customer1@example.com'
    @customer1.save!
    @customer1.reload

    assert_not(@customer1.preferences[:mail_delivery_failed], true)
    assert(@customer1.preferences[:mail_delivery_failed_data])

  end

end

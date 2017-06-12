# encoding: utf-8
require 'test_helper'

class EmailAddressTest < ActiveSupport::TestCase
  test 'basic tests' do

    email_address1 = EmailAddress.create_or_update(
      realname: 'address #1',
      email: 'address1@example.com',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_not(email_address1.active)

    email_address1.channel_id = Channel.first.id
    email_address1.save

    assert(email_address1.active)
  end

  test 'group tests' do

    email_address1 = EmailAddress.create_or_update(
      realname: 'address #1',
      email: 'address1@example.com',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    group1 = Group.create_or_update(
      name: 'group email address 1',
      email_address_id: email_address1.id,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(group1.email_address_id)
    email_address1.destroy

    group1 = Group.find(group1.id)
    assert_nil(group1.email_address_id, 'References to groups are deleted')
  end

  test 'channel tests' do

    channel1 = Channel.create(
      area: 'Email::Account',
      options: {},
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    email_address1 = EmailAddress.create_or_update(
      realname: 'address #1',
      email: 'address1@example.com',
      active: true,
      channel_id: channel1.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    email_address2 = EmailAddress.create_or_update(
      realname: 'address #2',
      email: 'address2@example.com',
      active: true,
      channel_id: channel1.id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    channel1.destroy

    email_address1 = EmailAddress.find(email_address1.id)
    assert_not(email_address1.channel_id)

    email_address2 = EmailAddress.find(email_address2.id)
    assert_not(email_address2.channel_id)

    channel1 = Channel.create(
      area: 'Email::Account',
      options: {},
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    email_address1 = EmailAddress.find(email_address1.id)
    assert_not(email_address1.channel_id)

    email_address2 = EmailAddress.find(email_address2.id)
    assert_not(email_address2.channel_id)
  end

end


require 'test_helper'

class TicketArticleStoreEmpty < ActiveSupport::TestCase

  test 'check if attachments are deleted after ticket is deleted' do

    current_count = Store.count
    current_file_count = Store::File.count
    current_backend_count = Store::Provider::DB.count

    email_raw_string = File.read(Rails.root.join('test', 'data', 'mail', 'mail001.box'))
    ticket, article, user, mail = Channel::EmailParser.new.process({}, email_raw_string)

    next_count = Store.count
    next_file_count = Store::File.count
    next_backend_count = Store::Provider::DB.count

    assert_equal(current_count, next_count - 2)
    assert_equal(current_file_count, next_file_count - 2)
    assert_equal(current_backend_count, next_backend_count - 2)

    ticket.destroy!

    after_count = Store.count
    after_file_count = Store::File.count
    after_backend_count = Store::Provider::DB.count

    assert_equal(current_count, after_count)
    assert_equal(current_file_count, after_file_count)
    assert_equal(current_backend_count, after_backend_count)

  end

  test 'check if attachments are deleted after ticket same ticket 2 times is deleted' do

    current_count = Store.count
    current_file_count = Store::File.count
    current_backend_count = Store::Provider::DB.count

    email_raw_string = File.read(Rails.root.join('test', 'data', 'mail', 'mail001.box'))
    ticket1, article1, user1, mail1 = Channel::EmailParser.new.process({}, email_raw_string)
    ticket2, article2, user2, mail2 = Channel::EmailParser.new.process({}, email_raw_string)

    next_count = Store.count
    next_file_count = Store::File.count
    next_backend_count = Store::Provider::DB.count

    assert_equal(current_count, next_count - 4)
    assert_equal(current_file_count, next_file_count - 2)
    assert_equal(current_backend_count, next_backend_count - 2)

    ticket1.destroy!

    next_count = Store.count
    next_file_count = Store::File.count
    next_backend_count = Store::Provider::DB.count

    assert_equal(current_count, next_count - 2)
    assert_equal(current_file_count, next_file_count - 2)
    assert_equal(current_backend_count, next_backend_count - 2)

    ticket2.destroy!

    after_count = Store.count
    after_file_count = Store::File.count
    after_backend_count = Store::Provider::DB.count

    assert_equal(current_count, after_count)
    assert_equal(current_file_count, after_file_count)
    assert_equal(current_backend_count, after_backend_count)

  end

end

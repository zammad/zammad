
require 'test_helper'

class EmailProcessIdentifySenderMax < ActiveSupport::TestCase

  test 'text max created recipients per email' do
    current_users = User.count
    email_raw_string = "From: #{generate_recipient}
To: #{generate_recipient(22)}
Cc: #{generate_recipient(22)}
Subject: test max sender identify

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    assert_equal('test max sender identify', ticket.title)
    assert_equal(current_users + 41, User.count)
  end

  def generate_recipient(count = 1)
    uid = -> { rand(999_999_999_999_999) }
    Array.new(count) { "#{uid.call}@#{uid.call}.example.com" }.join(', ')
  end

end

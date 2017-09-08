# encoding: utf-8
require 'test_helper'

class TicketArticleDos < ActiveSupport::TestCase

  test 'check body size' do

    org_community = Organization.create_if_not_exists(
      name: 'Zammad Foundation',
    )
    user_community = User.create_or_update(
      login: 'article.dos@example.org',
      firstname: 'Article',
      lastname: 'Dos',
      email: 'article.dos@example.org',
      password: '',
      active: true,
      roles: [ Role.find_by(name: 'Customer') ],
      organization_id: org_community.id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    UserInfo.current_user_id = user_community.id
    ApplicationHandleInfo.current = 'test.postmaster'

    ticket1 = Ticket.create!(
      group_id: Group.first.id,
      customer_id: user_community.id,
      title: 'DoS 1!',
      updated_by_id: 1,
      created_by_id: 1,
    )
    article1 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      type_id: Ticket::Article::Type.find_by(name: 'phone').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      from: 'Zammad Feedback <feedback@example.org>',
      body: Array.new(2_000_000) { [*'0'..'9', *'a'..'z', ' ', ' ', ' ', '. '].sample }.join,
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(1_500_000, article1.body.length)

    ticket2 = Ticket.create!(
      group_id: Group.first.id,
      customer_id: user_community.id,
      title: 'DoS 2!',
      updated_by_id: 1,
      created_by_id: 1,
    )
    article2 = Ticket::Article.create!(
      ticket_id: ticket2.id,
      type_id: Ticket::Article::Type.find_by(name: 'phone').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      from: 'Zammad Feedback <feedback@example.org>',
      body: "\u0000#{Array.new(2_000_000) { [*'0'..'9', *'a'..'z', ' ', ' ', ' ', '. '].sample }.join}",
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(1_500_000, article2.body.length)

    ApplicationHandleInfo.current = 'web'

    ticket3 = Ticket.create!(
      group_id: Group.first.id,
      customer_id: user_community.id,
      title: 'DoS 3!',
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_raises(Exceptions::UnprocessableEntity) {
      article3 = Ticket::Article.create!(
        ticket_id: ticket3.id,
        type_id: Ticket::Article::Type.find_by(name: 'phone').id,
        sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
        from: 'Zammad Feedback <feedback@example.org>',
        body: "\u0000#{Array.new(2_000_000) { [*'0'..'9', *'a'..'z', ' ', ' ', ' ', '. '].sample }.join}",
        internal: false,
        updated_by_id: 1,
        created_by_id: 1,
      )
    }

  end

  test 'check body size / cut if email' do

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text" + Array.new(2_000_000) { [*'0'..'9', *'a'..'z', ' ', ' ', ' ', '. '].sample }.join

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(1_500_000, article_p.body.length)

  end

end

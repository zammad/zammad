# encoding: utf-8
require 'test_helper'

class TicketArticleTwitter < ActiveSupport::TestCase

  test 'preferences cleanup' do

    org_community = Organization.create_if_not_exists(
      name: 'Zammad Foundation',
    )
    user_community = User.create_or_update(
      login: 'article.twitter@example.org',
      firstname: 'Article',
      lastname: 'Twitter',
      email: 'article.twitter@example.org',
      password: '',
      active: true,
      roles: [ Role.find_by(name: 'Customer') ],
      organization_id: org_community.id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      group_id: Group.first.id,
      customer_id: user_community.id,
      title: 'Tweet 1!',
      updated_by_id: 1,
      created_by_id: 1,
    )
    article1 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      type_id: Ticket::Article::Type.find_by(name: 'twitter status').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      from: '@example',
      body: 'some tweet',
      internal: false,
      preferences: TweetBase.new.preferences_cleanup(ActiveSupport::HashWithIndifferentAccess.new(
                                                       twitter: {
                                                         'mention_ids' => [1_234_567_890],
                                                         'geo' => Twitter::NullObject.new,
                                                         'retweeted' => false,
                                                         'possibly_sensitive' => false,
                                                         'in_reply_to_user_id' => 1_234_567_890,
                                                         'place' => Twitter::NullObject.new,
                                                         'retweet_count' => 0,
                                                         'source' => '<a href="http://example.com/software/tweetbot/mac" rel="nofollow">Tweetbot for Mac</a>',
                                                         'favorited' => false,
                                                         'truncated' => false
                                                       },
                                                       links: [
                                                         {
                                                           url: 'https://twitter.com/statuses/123',
                                                           target: '_blank',
                                                           name: 'on Twitter',
                                                         },
                                                       ],
      )),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(article1.preferences[:twitter])
    assert_equal(1_234_567_890, article1.preferences[:twitter][:mention_ids][0])
    assert_nil(article1.preferences[:twitter][:geo])
    assert_equal(NilClass, article1.preferences[:twitter][:geo].class)

  end

end

require 'rails_helper'

require_dependency 'channel/driver/twitter'

RSpec.describe ::Channel::Driver::Twitter do

  let(:channel) do
    create(
      :channel,
      area: 'Twitter::Account',
      options: {
        adapter: 'twitter',
        auth: {
          consumer_key:       'some',
          consumer_secret:    'some',
          oauth_token:        'key',
          oauth_token_secret: 'secret',
        },
        user: {
          screen_name: 'system_login',
          id: 'system_id',
        },
        sync: {
          track_retweets: true,
          search: [
            {
              term: 'zammad',
              group_id: Group.first.id,
            },
            {
              term: 'hash_tag1',
              group_id: Group.first.id,
            },
          ],
          mentions: {
            group_id: Group.first.id,
          },
          direct_messages: {
            group_id: Group.first.id,
          }
        }

      },
      active: true,
      created_by_id: 1,
      updated_by_id: 1
    )
  end

  it 'fetch channel with invalid token' do
    VCR.use_cassette('models/channel/driver/twitter/fetch_channel_invalid') do
      expect(channel.fetch(true)).to be false
    end

    channel.reload
    expect(channel.status_in).to eq('error')
    expect(channel.last_log_in).to eq('Can\'t use Channel::Driver::Twitter: #<Twitter::Error::Unauthorized: Invalid or expired token.>')
    expect(channel.status_out).to be nil
    expect(channel.last_log_out).to be nil
  end

  it 'fetch channel with valid token' do
    expect(Ticket.count).to eq(1)
    VCR.use_cassette('models/channel/driver/twitter/fetch_channel_valid') do
      expect(channel.fetch(true)).to be true
    end

    expect(Ticket.count).to eq(27)

    ticket = Ticket.last
    expect(ticket.title).to eq('Wir haben unsere DMs deaktiviert. Leider können wir dank der neuen Twitter API k...')
    expect(ticket.preferences[:channel_id]).to eq(channel.id)
    expect(ticket.preferences[:channel_screen_name]).to eq(channel.options[:user][:screen_name])
    expect(ticket.customer.firstname).to eq('Ccc')
    expect(ticket.customer.lastname).to eq('Event Logistics')

    channel.reload
    expect(channel.status_in).to eq('ok')
    expect(channel.last_log_in).to eq('')
    expect(channel.status_out).to be nil
    expect(channel.last_log_out).to be nil
  end

  it 'send tweet based on article - outbound' do
    user   = User.find(2)
    text   = 'Today the weather is really...'
    ticket = Ticket.create!(
      title:         text[0, 40],
      customer_id:   user.id,
      group_id:      Group.first.id,
      state:         Ticket::State.find_by(name: 'new'),
      priority:      Ticket::Priority.find_by(name: '2 normal'),
      preferences: {
        channel_id: channel.id,
        channel_screen_name: 'system_login',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, "outbound ticket created, text: #{text}")
    article = Ticket::Article.create!(
      ticket_id:     ticket.id,
      body:          text,
      type:          Ticket::Article::Type.find_by(name: 'twitter status'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    VCR.use_cassette('models/channel/driver/twitter/article_to_tweet') do
      Scheduler.worker(true)
    end

    ticket.reload
    expect(ticket.state.name).to eq('open')
    expect(ticket.group.name).to eq(Group.first.name)
    expect(ticket.title).to eq('Today the weather is really...')

    article.reload
    expect(article.from).to eq('@example')
    expect(article.to).to eq('')
    expect(article.cc).to be nil
    expect(article.subject).to be nil
    expect(article.sender.name).to eq('Agent')
    expect(article.type.name).to eq('twitter status')
    expect(article.message_id).to eq('1069382411899817990')
    expect(article.content_type).to eq('text/plain')
    expect(article.body).to eq('Today the weather is really...')
    expect(article.preferences[:links][0][:url]).to eq('https://twitter.com/statuses/1069382411899817990')
    expect(article.preferences[:links][0][:target]).to eq('_blank')
    expect(article.preferences[:links][0][:name]).to eq('on Twitter')

    channel.reload
    expect(channel.status_in).to be nil
    expect(channel.last_log_in).to be nil
    expect(channel.status_out).to eq('ok')
    expect(channel.last_log_out).to eq('')
  end

  it 'send tweet based on article - with replaced channel' do
    user = User.find(2)
    text   = 'Today and tomorrow the weather is really...'
    ticket = Ticket.create!(
      title:         text[0, 40],
      customer_id:   user.id,
      group_id:      Group.first.id,
      state:         Ticket::State.find_by(name: 'new'),
      priority:      Ticket::Priority.find_by(name: '2 normal'),
      preferences: {
        channel_id: 'some_other_id',
        channel_screen_name: 'system_login',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, "outbound ticket created, text: #{text}")
    article = Ticket::Article.create!(
      ticket_id:     ticket.id,
      body:          text,
      type:          Ticket::Article::Type.find_by(name: 'twitter status'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    channel.reload
    expect(channel.options[:user][:screen_name]).not_to be ticket.preferences[:channel_screen_name]
    expect(channel.status_in).to be nil
    expect(channel.last_log_in).to be nil
    expect(channel.status_out).to be nil
    expect(channel.last_log_out).to be nil

    VCR.use_cassette('models/channel/driver/twitter/article_to_tweet_channel_replace') do
      Scheduler.worker(true)
    end

    ticket.reload
    expect(ticket.state.name).to eq('open')
    expect(ticket.group.name).to eq(Group.first.name)
    expect(ticket.title).to eq('Today and tomorrow the weather is really')

    article.reload
    expect(article.from).to eq('@example')
    expect(article.to).to eq('')
    expect(article.cc).to be nil
    expect(article.subject).to be nil
    expect(article.sender.name).to eq('Agent')
    expect(article.type.name).to eq('twitter status')
    expect(article.message_id).to eq('1069382411899817991')
    expect(article.content_type).to eq('text/plain')
    expect(article.body).to eq('Today and tomorrow the weather is really...')
    expect(article.preferences[:links][0][:url]).to eq('https://twitter.com/statuses/1069382411899817991')
    expect(article.preferences[:links][0][:target]).to eq('_blank')
    expect(article.preferences[:links][0][:name]).to eq('on Twitter')

    channel.reload
    expect(channel.status_in).to be nil
    expect(channel.last_log_in).to be nil
    expect(channel.status_out).to eq('ok')
    expect(channel.last_log_out).to eq('')
  end

  it 'article preferences' do

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
    twitter_preferences = {
      mention_ids: [1_234_567_890],
      geo: Twitter::NullObject.new,
      retweeted: false,
      possibly_sensitive: false,
      in_reply_to_user_id: 1_234_567_890,
      place: Twitter::NullObject.new,
      retweet_count: 0,
      source: '<a href="http://example.com/software/tweetbot/mac" rel="nofollow">Tweetbot for Mac</a>',
      favorited: false,
      truncated: false
    }
    preferences = {
      twitter: TwitterSync.preferences_cleanup(twitter_preferences),
      links: [
        {
          url: 'https://twitter.com/statuses/123',
          target: '_blank',
          name: 'on Twitter',
        },
      ],
    }
    article1 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      type_id: Ticket::Article::Type.find_by(name: 'twitter status').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      from: '@example',
      body: 'some tweet',
      internal: false,
      preferences: TwitterSync.preferences_cleanup(preferences),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(article1.preferences[:twitter]).to be_truthy
    expect(article1.preferences[:twitter][:mention_ids][0]).to eq(1_234_567_890)
    expect(article1.preferences[:twitter][:geo].class).to be ActiveSupport::HashWithIndifferentAccess
    expect(article1.preferences[:twitter][:geo].blank?).to be true
    expect(article1.preferences[:twitter][:place].class).to be ActiveSupport::HashWithIndifferentAccess
    expect(article1.preferences[:twitter][:place].blank?).to be true

    twitter_preferences = {
      mention_ids: [1_234_567_890],
      geo: Twitter::NullObject.new,
      retweeted: false,
      possibly_sensitive: false,
      in_reply_to_user_id: 1_234_567_890,
      place: Twitter::NullObject.new,
      retweet_count: 0,
      source: '<a href="http://example.com/software/tweetbot/mac" rel="nofollow">Tweetbot for Mac</a>',
      favorited: false,
      truncated: false
    }
    preferences = TwitterSync.preferences_cleanup(
      twitter: twitter_preferences,
      links: [
        {
          url: 'https://twitter.com/statuses/123',
          target: '_blank',
          name: 'on Twitter',
        },
      ],
    )
    article2 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      type_id: Ticket::Article::Type.find_by(name: 'twitter status').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      from: '@example',
      body: 'some tweet',
      internal: false,
      preferences: TwitterSync.preferences_cleanup(preferences),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(article2.preferences[:twitter]).to be_truthy
    expect(article2.preferences[:twitter][:mention_ids][0]).to eq(1_234_567_890)
    expect(article1.preferences[:twitter][:geo].class).to be ActiveSupport::HashWithIndifferentAccess
    expect(article1.preferences[:twitter][:geo].blank?).to be true
    expect(article1.preferences[:twitter][:place].class).to be ActiveSupport::HashWithIndifferentAccess
    expect(article1.preferences[:twitter][:place].blank?).to be true

    twitter_preferences = {
      mention_ids: [1_234_567_890],
      geo: Twitter::Geo.new(coordinates: [1, 1]),
      retweeted: false,
      possibly_sensitive: false,
      in_reply_to_user_id: 1_234_567_890,
      place: Twitter::Place.new(country: 'da', name: 'do', woeid: 1, id: 1),
      retweet_count: 0,
      source: '<a href="http://example.com/software/tweetbot/mac" rel="nofollow">Tweetbot for Mac</a>',
      favorited: false,
      truncated: false
    }
    preferences = {
      twitter: TwitterSync.preferences_cleanup(twitter_preferences),
      links: [
        {
          url: 'https://twitter.com/statuses/123',
          target: '_blank',
          name: 'on Twitter',
        },
      ],
    }

    article3 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      type_id: Ticket::Article::Type.find_by(name: 'twitter status').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      from: '@example',
      body: 'some tweet',
      internal: false,
      preferences: preferences,
      updated_by_id: 1,
      created_by_id: 1,
    )

    expect(article3.preferences[:twitter]).to be_truthy
    expect(article3.preferences[:twitter][:mention_ids][0]).to eq(1_234_567_890)
    expect(article3.preferences[:twitter][:geo].class).to be ActiveSupport::HashWithIndifferentAccess
    expect(article3.preferences[:twitter][:geo]).to eq({ 'coordinates' => [1, 1] })
    expect(article3.preferences[:twitter][:place].class).to be ActiveSupport::HashWithIndifferentAccess
    expect(article3.preferences[:twitter][:place]).to eq({ 'country' => 'da', 'name' => 'do', 'woeid' => 1, 'id' => 1 })

    twitter_preferences = {
      mention_ids: [1_234_567_890],
      geo: Twitter::Geo.new(coordinates: [1, 1]),
      retweeted: false,
      possibly_sensitive: false,
      in_reply_to_user_id: 1_234_567_890,
      place: Twitter::Place.new(country: 'da', name: 'do', woeid: 1, id: 1),
      retweet_count: 0,
      source: '<a href="http://example.com/software/tweetbot/mac" rel="nofollow">Tweetbot for Mac</a>',
      favorited: false,
      truncated: false
    }
    preferences = TwitterSync.preferences_cleanup(
      twitter: twitter_preferences,
      links: [
        {
          url: 'https://twitter.com/statuses/123',
          target: '_blank',
          name: 'on Twitter',
        },
      ],
    )

    article4 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      type_id: Ticket::Article::Type.find_by(name: 'twitter status').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      from: '@example',
      body: 'some tweet',
      internal: false,
      preferences: preferences,
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(article4.preferences[:twitter]).to be_truthy
    expect(article4.preferences[:twitter]).to be_truthy
    expect(article4.preferences[:twitter][:mention_ids][0]).to eq(1_234_567_890)
    expect(article4.preferences[:twitter][:geo].class).to be ActiveSupport::HashWithIndifferentAccess
    expect(article4.preferences[:twitter][:geo]).to eq({ 'coordinates' => [1, 1] })
    expect(article4.preferences[:twitter][:place].class).to be ActiveSupport::HashWithIndifferentAccess
    expect(article4.preferences[:twitter][:place]).to eq({ 'country' => 'da', 'name' => 'do', 'woeid' => 1, 'id' => 1 })
  end
end

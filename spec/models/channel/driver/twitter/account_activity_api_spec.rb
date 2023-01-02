# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Twitter > Account Activity API', integration: true, required_envs: %w[TWITTER_CONSUMER_KEY TWITTER_CONSUMER_SECRET TWITTER_OAUTH_TOKEN TWITTER_OAUTH_TOKEN_SECRET TWITTER_USER_ID TWITTER_DM_REAL_RECIPIENT TWITTER_SEARCH_CONSUMER_KEY TWITTER_SEARCH_CONSUMER_SECRET TWITTER_SEARCH_OAUTH_TOKEN TWITTER_SEARCH_OAUTH_TOKEN_SECRET TWITTER_SEARCH_USER_ID], use_vcr: :time_sensitive do # rubocop:disable RSpec/DescribeClass
  subject(:channel) { create(:twitter_channel, custom_options: { sync: { search: nil } }) }

  let(:twitter_helper) do
    RSpecTwitter::Helper.new(auth_data_search_app)
  end

  let(:twitter_helper_channel) do
    RSpecTwitter::Helper.new(auth_data_channel_app)
  end

  let(:channel_attributes) do
    {
      'status_in'    => 'ok',
      'last_log_in'  => '',
      'status_out'   => nil,
      'last_log_out' => nil,
    }
  end

  def auth_data_channel_app
    {
      consumer_key:       ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret:    ENV['TWITTER_CONSUMER_SECRET'],
      oauth_token:        ENV['TWITTER_OAUTH_TOKEN'],
      oauth_token_secret: ENV['TWITTER_OAUTH_TOKEN_SECRET'],
    }
  end

  def auth_data_search_app
    {
      consumer_key:       ENV['TWITTER_SEARCH_CONSUMER_KEY'],
      consumer_secret:    ENV['TWITTER_SEARCH_CONSUMER_SECRET'],
      oauth_token:        ENV['TWITTER_SEARCH_OAUTH_TOKEN'],
      oauth_token_secret: ENV['TWITTER_SEARCH_OAUTH_TOKEN_SECRET'],
    }
  end

  before :all do # rubocop:disable RSpec/BeforeAfterAll
    if %w[1 true].include?(ENV['CI_IGNORE_CASSETTES'])
      RSpecTwitter::Helper.new(auth_data_search_app).delete_old_tweets
      RSpecTwitter::Helper.new(auth_data_channel_app).delete_old_tweets
    end
  end

  it 'sets successful status attributes' do
    expect { channel.fetch }
      .to change { channel.reload.attributes }
      .to hash_including(channel_attributes)
  end

  context 'with search term configured' do
    subject(:channel) { create(:twitter_channel, custom_options: { sync: { search: [ { term: identifier, group_id: Group.first.id } ] } }) }

    let(:identifier) do
      random_number = %w[1 true].include?(ENV['CI_IGNORE_CASSETTES']) ? SecureRandom.uuid.delete('-') : '0509d41afd66476fa52a1c3892f669eb'

      "zammad_testing_#{random_number}"
    end

    let(:ticket_title) { "Come and join our team to bring Zammad even further forward! #{identifier}" }

    after do
      twitter_helper.delete_all_tweets(identifier)
      twitter_helper_channel.delete_all_tweets(identifier)
    end

    context 'with recent tweets' do
      before do
        twitter_helper.create_tweet(ticket_title)
        twitter_helper.create_tweet("dummy API activity test! #{identifier}")

        twitter_helper_channel.ensure_tweet_availability(identifier, 2)
      end

      let(:expected_ticket_attributes) do
        {
          'title'       => ticket_title.size > 80 ? "#{ticket_title[0..79]}..." : ticket_title,
          'preferences' => {
            'channel_id'          => channel.id,
            'channel_screen_name' => channel.options[:user][:screen_name]
          },
        }
      end

      it 'creates an article for each recent tweet', :aggregate_failures do
        expect { channel.fetch }.to change(Ticket, :count).by(2)

        expect(Ticket.last.attributes).to include(expected_ticket_attributes)
      end
    end

    context 'with responses to other tweets' do
      before do
        parent_tweet = twitter_helper.create_tweet('Parent tweet without identifier')
        twitter_helper.create_tweet("Response test! #{identifier}", in_reply_to_status_id: parent_tweet.id)

        twitter_helper_channel.ensure_tweet_availability(identifier, 1)
      end

      let(:ticket_articles) { Ticket.last.articles }

      it 'creates articles for parent tweets as well', :aggregate_failures do
        expect { channel.fetch }.to change(Ticket, :count).by(1)

        expect(ticket_articles.first.body).not_to include(identifier)  # parent tweet
        expect(ticket_articles.last.body).to include(identifier)       # search result
      end
    end

    context 'with "track_retweets" option' do
      before do
        tweet = twitter_helper_channel.create_tweet("Zammad is amazing! #{identifier}")
        twitter_helper.create_retweet(tweet.id)

        twitter_helper_channel.ensure_tweet_availability(identifier, 2)
      end

      context 'when set to false' do
        it 'skips retweets' do
          expect { channel.fetch }
            .not_to change { Ticket.where('title LIKE ?', 'RT @%').count }.from(0)
        end
      end

      context 'when set to true' do
        subject(:channel) { create(:twitter_channel, custom_options: { sync: { track_retweets: true, search: [ { term: identifier, group_id: Group.first.id } ] } }) }

        it 'creates an article for each recent tweet/retweet' do
          expect { channel.fetch }
            .to change { Ticket.where('title LIKE ?', 'RT @%').count }.by(1)
            .and change(Ticket, :count).by(1)
        end
      end
    end

    context 'with "import_older_tweets" option' do
      before do
        twitter_helper.create_tweet("Zammad is amazing! #{identifier}")
        twitter_helper.create_tweet("Such. A. Beautiful. Helpdesk. Tool. #{identifier}")
        twitter_helper.create_tweet("Need a helpdesk tool? Zammad <3 #{identifier}")
        twitter_helper_channel.ensure_tweet_availability(identifier, 3)

        travel 16.days
        channel.update!(created_at: Time.zone.now.utc)
        travel_back
      end

      context 'when false (default)' do
        it 'skips tweets 15+ days older than channel itself' do
          expect { channel.fetch }.not_to change(Ticket, :count)
        end
      end

      context 'when true' do
        subject(:channel) { create(:twitter_channel, custom_options: { sync: { import_older_tweets: true, search: [ { term: identifier, group_id: Group.first.id } ] } }) }

        it 'creates an article for each tweet' do
          expect { channel.fetch }.to change(Ticket, :count).by(3)
        end
      end
    end

    context 'when fetched tweets have already been imported' do
      before do
        tweet_ids = []
        3.times do |index|
          tweet = twitter_helper.create_tweet("Tweet #{index}! #{identifier}")

          tweet_ids << tweet.id
        end
        twitter_helper_channel.ensure_tweet_availability(identifier, 3)

        tweet_ids.each { |tweet_id| create(:ticket_article, message_id: tweet_id) }
      end

      it 'does not import duplicates' do
        expect { channel.fetch }.not_to change(Ticket::Article, :count)
      end
    end

    context 'with a very common search term' do
      subject(:channel) { create(:twitter_channel, custom_options: { sync: { search: [ { term: 'corona', group_id: Group.first.id } ] } }) }

      let(:twitter_articles) { Ticket::Article.joins(:type).where(ticket_article_types: { name: 'twitter status' }) }

      before do
        stub_const('TwitterSync::MAX_TWEETS_PER_IMPORT', 10)
      end

      # Note that this rate limiting is partially duplicated
      # in #fetchable?, which prevents #fetch from running
      # more than once in a 20-minute period.
      it 'imports max. ~120 articles every 15 minutes', :aggregate_failures do
        freeze_time

        channel.fetch

        expect((twitter_articles - Ticket.last.articles).count).to be <= 10
        expect(twitter_articles.count).to be > 10

        travel(10.minutes)

        expect { channel.fetch }.not_to change(Ticket::Article, :count)

        travel(6.minutes)

        expect { channel.fetch }.to change(Ticket::Article, :count)

        travel_back
      end
    end
  end
end

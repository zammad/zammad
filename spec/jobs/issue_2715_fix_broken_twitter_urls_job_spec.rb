# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require_dependency 'issue_2715_fix_broken_twitter_urls_job' # Rails autoloading expects `issue2715_fix...`

RSpec.describe Issue2715FixBrokenTwitterUrlsJob, type: :job do
  context 'with existing Twitter articles' do
    let!(:tweet) { create(:twitter_article, preferences: tweet_preferences) }
    let!(:dm) { create(:twitter_dm_article, preferences: dm_preferences) }

    let(:tweet_preferences) do
      # NOTE: Faker 2.0+ has deprecated the `#number(20)` syntax in favor of `#number(digits: 20)`.
      { links: [{ url: "https://twitter.com/statuses/#{Faker::Number.number(20)}" }] }
    end

    let(:dm_preferences) do
      {
        # NOTE: Faker 2.0+ has deprecated the `#number(20)` syntax in favor of `#number(digits: 20)`.
        links:   [{ url: "https://twitter.com/statuses/#{Faker::Number.number(20)}" }],
        twitter: {
          recipient_id: recipient_id,
          sender_id:    sender_id,
        },
      }
    end

    let(:recipient_id) { '1234567890' }
    let(:sender_id) { '0987654321' }

    it 'reformats all Twitter status URLs' do
      expect { described_class.perform_now }
        .to change { urls_of(tweet) }
        .to all(match(%r{^https://twitter.com/_/status/#{tweet.message_id}$}))
    end

    it 'reformats all Twitter DM URLs' do
      expect { described_class.perform_now }
        .to change { urls_of(dm) }
        .to all(match(%r{^https://twitter.com/messages/#{recipient_id}-#{sender_id}$}))
    end

    def urls_of(article)
      article.reload.preferences[:links].pluck(:url)
    end
  end
end

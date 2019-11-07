require 'rails_helper'
require_dependency 'issue_2715_fix_broken_twitter_urls_job' # Rails autoloading expects `issue2715_fix...`

RSpec.describe Issue2715FixBrokenTwitterUrlsJob, type: :job do
  context 'with existing Twitter articles' do
    let!(:dm) { create(:twitter_dm_article, preferences: dm_preferences) }

    let(:dm_preferences) do
      {
        links:   Array.new(5, &link_hash),
        twitter: {
          recipient_id: recipient_id,
          sender_id:    sender_id,
        },
      }
    end

    # NOTE: Faker 2.0+ has deprecated the `#number(20)` syntax in favor of `#number(digits: 20)`.
    let(:link_hash) { ->(_) { { url: "https://twitter.com/statuses/#{Faker::Number.number(20)}" } } }
    let(:recipient_id) { '1234567890' }
    let(:sender_id) { '0987654321' }

    it 'reformats all Twitter DM URLs' do
      expect { described_class.perform_now }
        .to change { urls_of(dm) }
        .to all(match(%r{^https://twitter.com/messages/#{recipient_id}-#{sender_id}$}))
    end

    def urls_of(article)
      article.reload.preferences[:links].map { |link| link[:url] }
    end
  end
end

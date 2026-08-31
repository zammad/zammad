# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# A tag listing collects answers across categories, and `KnowledgeBase::Answer.tag_objects` is a
#   bare `where`, so nothing presets their category: without the preload in
#   `KnowledgeBase::Public::BaseController#answers_filter` the list is an N+1, one round trip per
#   listed answer, for anonymous visitors as much as for editors. Pinned here rather than left to
#   the comment on that method.
RSpec.describe 'KnowledgeBase public preloading', type: :request do
  include_context 'basic Knowledge Base'

  before do
    # Skip asset generation.
    allow_any_instance_of(ActionView::Base).to receive(:compute_asset_path).and_return('')
  end

  # Round trips only: `payload[:cached]` repeats are the ones Rails' per-request query cache
  #   answers without going to the database, and those are not what this is about.
  def category_query_count(&)
    queries = 0

    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      next if payload[:cached] || payload[:name] == 'SCHEMA'

      queries += 1 if payload[:sql].include?('"knowledge_base_categories"')
    end

    yield

    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  describe 'a tag listing' do
    def create_tagged_answer_in_own_category
      create(:knowledge_base_answer, :published, :with_tag,
             tag_names: [published_answer_tag_name],
             category:  create(:knowledge_base_category, knowledge_base: knowledge_base))
    end

    def request_tag_page
      category_query_count { get help_tag_path(locale_name, published_answer_tag_name) }
    end

    # Each answer in its own category, and the count taken as a guest: the link the view builds
    #   (`answer.category.translation`) needs the category for every visitor, the editor-only policy
    #   check asking whether its knowledge base is active only adds to it.
    it 'fetches the categories of the listed answers in a constant number of queries' do
      create_tagged_answer_in_own_category
      baseline = request_tag_page

      # The request leaves UserInfo cleared behind it, which tagging needs.
      UserInfo.current_user_id = 1
      3.times { create_tagged_answer_in_own_category }

      expect(request_tag_page).to eq(baseline)
    end
  end
end

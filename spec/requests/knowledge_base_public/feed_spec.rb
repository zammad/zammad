# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase public feed', type: :request do
  include_context 'basic Knowledge Base'

  before do
    # Skip asset generation: the not found page links stylesheets the test environment does not compile.
    allow_any_instance_of(ActionView::Base).to receive(:compute_asset_path).and_return('')

    published_answer
    travel 1.minute
    published_answer_in_other_category
  end

  describe '#root' do
    before do
      get help_root_feed_path(locale_name)
    end

    it 'lists entries' do
      answer_index = response.body.index published_answer.translations.first.title
      answer_index2 = response.body.index published_answer_in_other_category.translations.first.title

      expect(answer_index > answer_index2).to be_truthy
    end

    it 'uses KB title' do
      expect(response.body).to include(knowledge_base.translations.first.title)
    end
  end

  describe '#category' do
    context 'with a public category' do
      before do
        get help_category_feed_path(locale_name, category)
      end

      it 'lists entries', :aggregate_failures do
        expect(response.body).to include(published_answer.translations.first.title)
        expect(response.body).not_to include(published_answer_in_other_category.translations.first.title)
      end

      it 'uses category title' do
        expect(response.body).to include(category.translations.first.title)
      end
    end

    context 'when the category has no published answers' do
      let(:hidden_category) { create(:knowledge_base_category, :containing_internal, knowledge_base: knowledge_base, translations: [build(:knowledge_base_category_translation, title: 'SecretCanary', kb_locale: primary_locale)]) }

      before do
        # The feed icon prints the category title in the layout head and the feed picker.
        knowledge_base.update!(show_feed_icon: true)
      end

      context 'when visited anonymously' do
        before do
          get help_category_feed_path(locale_name, hidden_category)
        end

        it 'is not found', :aggregate_failures do
          expect(response).to have_http_status(:not_found)
          expect(response.body).not_to match(%r{secretcanary}i)
        end
      end

      # The guard is the policy, not the published content alone: editors keep the feed.
      context 'when visited by an editor' do
        before do
          authenticated_as(create(:admin), via: :browser)

          get help_category_feed_path(locale_name, hidden_category)
        end

        it 'serves the feed', :aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('SecretCanary')
        end
      end
    end

    context 'when the category does not exist' do
      before do
        get help_category_feed_path(locale_name, 0)
      end

      it 'is not found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context 'with no answers' do
    before do
      Ticket.destroy_all
    end

    it 'loads' do
      get help_root_feed_path(locale_name)

      expect(response).to have_http_status :ok
    end
  end

  # Custom subdomain/path is handled by rewriting at the web server, which calls
  # the original /help URL with a custom URL in the request headers to simulate.
  describe 'generated feed URLs' do
    context 'without a custom address (default installation)' do
      before do
        get help_root_feed_path(locale_name)
      end

      it 'emits absolute URLs including the internal /help mount point', :aggregate_failures do
        expect(response.body).to include("http://www.example.com/help/#{locale_name}/feed")
        expect(response.body).to include("http://www.example.com/help/#{locale_name}/")
      end
    end

    context 'with a hostname-only custom address' do
      let(:knowledge_base) { create(:knowledge_base, custom_address: 'faq.example.com') }

      before do
        get help_root_feed_path(locale_name), headers: { SERVER_NAME: 'faq.example.com', HTTP_X_ORIGINAL_URL: "/#{locale_name}/feed" }
      end

      it 'does not leak the internal /help path' do
        expect(response.body).not_to include('/help')
      end

      it 'does not duplicate the host in generated URLs' do
        expect(response.body).not_to include('faq.example.comhttp')
      end

      it 'serves the feed and entries from the root of the custom host', :aggregate_failures do
        expect(response.body).to include("http://faq.example.com/#{locale_name}/feed")
        expect(response.body).to match(%r{href="http://faq\.example\.com/#{locale_name}/[^/]+/[^"]+"})
      end

      it 'uses the custom host without /help in the Atom feed id' do
        expect(response.body).to include("tag:faq.example.com,2005:/#{locale_name}/feed")
      end
    end

    context 'with a path-only custom address' do
      let(:knowledge_base) { create(:knowledge_base, custom_address: '/support') }

      before do
        get help_root_feed_path(locale_name), headers: { SERVER_NAME: 'www.example.com', HTTP_X_ORIGINAL_URL: "/support/#{locale_name}/feed" }
      end

      it 'rewrites the internal /help path to the custom path', :aggregate_failures do
        expect(response.body).not_to include('/help')
        expect(response.body).to include("http://www.example.com/support/#{locale_name}/feed")
      end
    end

    context 'with a custom address combining host and path' do
      let(:knowledge_base) { create(:knowledge_base, custom_address: 'faq.example.com/support') }

      before do
        get help_root_feed_path(locale_name), headers: { SERVER_NAME: 'faq.example.com', HTTP_X_ORIGINAL_URL: "/support/#{locale_name}/feed" }
      end

      it 'serves the feed from the custom host and path without leaking /help', :aggregate_failures do
        expect(response.body).not_to include('/help')
        expect(response.body).not_to include('faq.example.comhttp')
        expect(response.body).to include("http://faq.example.com/support/#{locale_name}/feed")
        expect(response.body).to include("tag:faq.example.com,2005:/support/#{locale_name}/feed")
      end
    end
  end
end

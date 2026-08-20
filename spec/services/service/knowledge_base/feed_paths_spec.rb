# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::FeedPaths do
  subject(:result) do
    described_class.with_current_user(user).execute(knowledge_base:, locale: primary_locale, category:)
  end

  include_context 'basic Knowledge Base'

  let(:user)     { create(:agent) }
  let(:category) { nil }
  let(:token)    { Token.find_by(action: 'KnowledgeBaseFeed', user_id: user.id) }

  it 'returns the knowledge base feed path carrying the access token' do
    expect(result[:knowledge_base_path])
      .to eq("/api/v1/knowledge_bases/#{knowledge_base.id}/#{locale_name}/feed?token=#{token.token}")
  end

  it 'offers no category feed at the knowledge base root' do
    expect(result[:category_path]).to be_nil
  end

  it 'creates a persistent token for the current user' do
    result

    expect(token).to have_attributes(persistent: true, user_id: user.id)
  end

  context 'when a token already exists' do
    let!(:existing_token) { Token.ensure_token!('KnowledgeBaseFeed', user.id, persistent: true) }

    it 'reuses it instead of minting a new one' do
      expect(result[:knowledge_base_path]).to include("token=#{existing_token}")
    end
  end

  context 'when renewing' do
    subject(:result) do
      described_class.with_current_user(user).execute(knowledge_base:, locale: primary_locale, renew: true)
    end

    let!(:existing_token) { Token.ensure_token!('KnowledgeBaseFeed', user.id, persistent: true) }

    it 'hands out a new token, invalidating the previous paths' do
      expect(result[:knowledge_base_path]).not_to include("token=#{existing_token}")
    end

    it 'keeps the token persistent' do
      result

      expect(token).to have_attributes(persistent: true, user_id: user.id)
    end

    context 'without an existing token' do
      let!(:existing_token) { nil }

      it 'creates one' do
        expect(result[:knowledge_base_path]).to include("token=#{token.token}")
      end
    end
  end

  context 'with a category' do
    let(:category) { create(:knowledge_base_category, knowledge_base:) }

    it 'additionally returns the category feed path' do
      expect(result[:category_path])
        .to eq("/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/#{locale_name}/feed?token=#{token.token}")
    end

    it 'uses the same token for both feeds' do
      expect(result[:category_path]).to include("token=#{result[:knowledge_base_path].split('token=').last}")
    end
  end

  context 'with an alternative locale' do
    subject(:result) do
      described_class.with_current_user(user).execute(knowledge_base:, locale: alternative_locale, category:)
    end

    it 'delivers the feed in that locale' do
      expect(result[:knowledge_base_path]).to include("/#{alternative_locale.system_locale.locale}/feed")
    end
  end

  context 'without a current user' do
    it 'is rejected' do
      expect { described_class.execute(knowledge_base:, locale: primary_locale) }
        .to raise_error(%r{Current user is required})
    end
  end
end

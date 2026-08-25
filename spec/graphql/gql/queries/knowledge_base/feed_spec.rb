# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# How the feed paths and their token are built is covered by
#   spec/services/service/knowledge_base/feed_paths_spec.rb — this covers the GraphQL surface only:
#   that the arguments reach the service, the payload, and authorization.
RSpec.describe Gql::Queries::KnowledgeBase::Feed, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:query) do
    <<~GQL
      query knowledgeBaseFeed($categoryId: ID, $locale: String) {
        knowledgeBaseFeed(categoryId: $categoryId, locale: $locale) {
          knowledgeBasePath
          categoryPath
        }
      }
    GQL
  end
  let(:variables) { {} }

  before do
    knowledge_base
    gql.execute(query, variables:)
  end

  shared_examples 'returning the knowledge base feed' do
    it 'returns the feed of all updates', :aggregate_failures do
      expect(gql.result.data['knowledgeBasePath'])
        .to include("/api/v1/knowledge_bases/#{knowledge_base.id}/#{locale_name}/feed?token=")
      expect(gql.result.data['categoryPath']).to be_nil
    end
  end

  context 'with an admin (editor)', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    include_examples 'returning the knowledge base feed'

    context 'with a category' do
      let(:variables) { { categoryId: gql.id(category) } }

      it 'passes it on, so the category feed is offered too' do
        expect(gql.result.data['categoryPath']).to include("/categories/#{category.id}/")
      end
    end

    context 'with an alternative locale' do
      let(:variables) { { locale: alternative_locale.system_locale.locale } }

      it 'passes it on, so the feed is delivered in that locale' do
        expect(gql.result.data['knowledgeBasePath'])
          .to include("/#{alternative_locale.system_locale.locale}/feed")
      end
    end
  end

  # Browsing is what the feed follows, so a reader gets one as well.
  context 'with an agent (reader)', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    include_examples 'returning the knowledge base feed'
  end

  context 'with a customer (no knowledge base permission)', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'is rejected' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'without authentication' do
    it 'is rejected' do
      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end

  # The feed URL carries an access token, so a category the user may not open must
  #   not get one either — the argument's Pundit gate is what enforces that.
  context 'when granular category permissions are configured' do
    let(:reader_role) { create(:role, permission_names: %w[knowledge_base.reader]) }
    let(:reader)      { create(:user, roles: [reader_role]) }
    let(:variables)   { { categoryId: gql.id(other_category) } }

    before do
      create(:knowledge_base_permission, permissionable: other_category, role: reader_role, access: 'none')
      gql.execute(query, variables:)
    end

    context 'with a reader requesting the feed of a denied category', authenticated_as: :reader do
      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  # Only the active knowledge base is browsable, so its feeds are the only ones
  #   there are — like for its answers, asking for another one's is an error.
  context 'when the knowledge base is inactive', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    before do
      knowledge_base.update!(active: false)
      gql.execute(query, variables:)
    end

    it 'is rejected' do
      expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
    end
  end
end

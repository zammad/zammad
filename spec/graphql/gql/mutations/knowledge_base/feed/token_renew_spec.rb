# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# How the paths and their token are built, and what renewing does to it, is covered by
#   spec/services/service/knowledge_base/feed_paths_spec.rb — this covers the GraphQL surface only:
#   that the mutation asks for a renewal, the payload, and authorization.
RSpec.describe Gql::Mutations::KnowledgeBase::Feed::TokenRenew, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:mutation) do
    <<~GQL
      mutation knowledgeBaseFeedTokenRenew($categoryId: ID, $locale: String) {
        knowledgeBaseFeedTokenRenew(categoryId: $categoryId, locale: $locale) {
          feed {
            knowledgeBasePath
            categoryPath
          }
          errors {
            message
            field
          }
        }
      }
    GQL
  end
  let(:variables) { {} }

  context 'when user is not authenticated' do
    before do
      knowledge_base
      gql.execute(mutation, variables:)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'with an agent (reader)', authenticated_as: :agent do
    let(:agent)          { create(:agent) }
    let!(:current_token) { Token.ensure_token!('KnowledgeBaseFeed', agent.id, persistent: true) }

    before do
      knowledge_base
      gql.execute(mutation, variables:)
    end

    it 'asks for a renewal, so the previous token no longer applies' do
      expect(Token.find_by(action: 'KnowledgeBaseFeed', user_id: agent.id).token).not_to eq(current_token)
    end

    # The renewed paths come back with the mutation, so the caller can replace the ones it shows
    #   in one step instead of fetching them again.
    it 'answers with the paths carrying the renewed token', :aggregate_failures do
      renewed = Token.find_by(action: 'KnowledgeBaseFeed', user_id: agent.id).token

      expect(gql.result.data['feed']['knowledgeBasePath'])
        .to eq("/api/v1/knowledge_bases/#{knowledge_base.id}/#{locale_name}/feed?token=#{renewed}")
      expect(gql.result.data['feed']['categoryPath']).to be_nil
    end

    context 'with a category' do
      let(:variables) { { categoryId: gql.id(category) } }

      it 'passes it on, so the category feed is offered too' do
        expect(gql.result.data['feed']['categoryPath']).to include("/categories/#{category.id}/")
      end
    end

    context 'with an alternative locale' do
      let(:variables) { { locale: alternative_locale.system_locale.locale } }

      it 'passes it on, so the feed is delivered in that locale' do
        expect(gql.result.data['feed']['knowledgeBasePath'])
          .to include("/#{alternative_locale.system_locale.locale}/feed")
      end
    end
  end

  context 'with a customer (no knowledge base permission)', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'is rejected' do
      gql.execute(mutation, variables:)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  # The renewed URL carries an access token, so a category the user may not open
  #   must not get one either.
  context 'when granular category permissions are configured' do
    let(:reader_role) { create(:role, permission_names: %w[knowledge_base.reader]) }
    let(:reader)      { create(:user, roles: [reader_role]) }
    let(:variables)   { { categoryId: gql.id(other_category) } }

    before do
      create(:knowledge_base_permission, permissionable: other_category, role: reader_role, access: 'none')
      gql.execute(mutation, variables:)
    end

    context 'with a reader renewing for a denied category', authenticated_as: :reader do
      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end

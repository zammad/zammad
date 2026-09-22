# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The behaviour is covered by spec/services/service/user/content_translation_auto_spec.rb.
RSpec.describe Gql::Mutations::User::Current::ContentTranslationAuto, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation userCurrentContentTranslationAuto($enabled: Boolean!) {
        userCurrentContentTranslationAuto(enabled: $enabled) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:variables) { { enabled: true } }

  context 'when logged in as an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    before { Setting.set('content_translation_ticket_article_auto', true) }

    it 'saves the preference and returns success', :aggregate_failures do
      gql.execute(query, variables:)

      expect(gql.result.data[:success]).to be(true)
      expect(agent.reload.preferences['content_translation_auto']).to be(true)
    end

    context 'with an agent the configured roles do not allow' do
      before { Setting.set('content_translation_ticket_article_auto_role_ids', [create(:role).id]) }

      it 'fails' do
        gql.execute(query, variables:)

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'when logged in as a customer', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'is not allowed' do
      gql.execute(query, variables:)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(query, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end

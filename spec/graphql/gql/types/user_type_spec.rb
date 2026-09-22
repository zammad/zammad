# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::UserType, authenticated_as: :agent, type: :graphql do
  # The rules themselves are covered by Service::ContentTranslation::TicketArticle::AutoAllowed.
  describe 'hasContentTranslationAutoAvailable' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        query currentUser {
          currentUser {
            hasContentTranslationAutoAvailable
          }
        }
      QUERY
    end

    let(:capability) { gql.result.data['hasContentTranslationAutoAvailable'] }

    before do
      Setting.set('content_translation_ticket_article_auto', auto)

      gql.execute(query)
    end

    context 'with automatic translation switched on' do
      let(:auto) { true }

      it 'answers that the user may translate automatically' do
        expect(capability).to be(true)
      end
    end

    context 'with automatic translation switched off' do
      let(:auto) { false }

      it 'answers that the user may not translate automatically' do
        expect(capability).to be(false)
      end
    end
  end
end

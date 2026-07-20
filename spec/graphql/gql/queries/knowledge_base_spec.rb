# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::KnowledgeBase, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:query) do
    <<~GQL
      query knowledgeBase($locale: String) {
        knowledgeBase(locale: $locale) {
          id
          title
          active
          isPubliclyAvailable
          isVisiblePublicly
          kbLocales {
            primary
            systemLocale { locale }
          }
          currentLocale {
            systemLocale { locale }
          }
        }
      }
    GQL
  end
  let(:variables) { {} }

  before do
    knowledge_base
    gql.execute(query, variables:)
  end

  shared_examples 'returning the active knowledge base' do
    it 'returns the knowledge base with the primary-locale title' do
      expect(gql.result.data).to include(
        'id'     => gql.id(knowledge_base),
        'title'  => knowledge_base.translation_primary.title,
        'active' => true,
      )
    end

    it 'exposes the available locales for the language selector' do
      expect(gql.result.data['kbLocales']).to include(
        include('primary' => true, 'systemLocale' => include('locale' => locale_name))
      )
    end

    it 'resolves the current locale (falling back to the primary locale)' do
      expect(gql.result.data['currentLocale']).to include('systemLocale' => include('locale' => locale_name))
    end
  end

  context 'with an admin (editor)', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    include_examples 'returning the active knowledge base'
  end

  context 'with an agent (reader)', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    include_examples 'returning the active knowledge base'
  end

  context 'with a customer (no knowledge base permission)', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    include_examples 'returning the active knowledge base'
  end

  context 'without authentication' do
    it 'is rejected' do
      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end

  context 'with public availability', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    context 'when no published content exists' do
      it 'is not publicly available' do
        expect(gql.result.data).to include('isPubliclyAvailable' => false)
      end

      it 'is not publicly visible in the requested locale' do
        expect(gql.result.data).to include('isVisiblePublicly' => false)
      end
    end

    context 'when published content exists' do
      before do
        published_answer
        gql.execute(query, variables:)
      end

      it 'is publicly available' do
        expect(gql.result.data).to include('isPubliclyAvailable' => true)
      end

      it 'is publicly visible in the requested locale' do
        expect(gql.result.data).to include('isVisiblePublicly' => true)
      end
    end
  end

  context 'when there is no active knowledge base', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    before do
      knowledge_base.update!(active: false)
      gql.execute(query, variables:)
    end

    it 'returns nothing' do
      expect(gql.result.data).to be_nil
    end
  end
end

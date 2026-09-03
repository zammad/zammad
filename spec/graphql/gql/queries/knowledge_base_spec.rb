# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::KnowledgeBase, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:query) do
    <<~GQL
      query knowledgeBase($locale: String) {
        knowledgeBase(locale: $locale) {
          id
          translation { title }
          active
          categorySortingMode
          isPubliclyAvailable
          isVisiblePublicly
          showFeedIcon
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
        'id'          => gql.id(knowledge_base),
        'translation' => include('title' => knowledge_base.translation_primary.title),
        'active'      => true,
      )
    end

    # How the top level categories are ordered is stored on the knowledge base itself, which is what
    #   the browse header reads to show the picker. The root lists categories only, so there is this
    #   one mode where a category has one per list.
    it 'exposes the sorting mode of the top level' do
      knowledge_base.update!(category_sorting_mode: 'last_update')
      gql.execute(query, variables:)

      expect(gql.result.data['categorySortingMode']).to eq('last_update')
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

  context 'with the feed icon setting', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'is disabled by default' do
      expect(gql.result.data).to include('showFeedIcon' => false)
    end

    context 'when enabled' do
      before do
        knowledge_base.update!(show_feed_icon: true)
        gql.execute(query, variables:)
      end

      it 'is exposed' do
        expect(gql.result.data).to include('showFeedIcon' => true)
      end
    end
  end

  context 'when there is no active knowledge base', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    before do
      knowledge_base.update!(active: false)
      gql.execute(query, variables:)
    end

    it 'is not found' do
      expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
    end
  end

  # The client hands the same `$locale` to the query and to every localized field of the result
  #   (knowledgeBase.graphql), so a code this knowledge base has no locale for must resolve the
  #   same way in both places. The query falls it back deliberately
  #   (Gql::Concerns::HandlesKnowledgeBaseLocale), and a field that answered `nil` instead would
  #   mix the locale the query settled on with another locale's texts - and hand back no
  #   `currentLocale` at all, which is what the section entry redirects on.
  context 'with a locale code the knowledge base has no locale for' do
    let(:query) do
      <<~GQL
        query knowledgeBase($locale: String) {
          knowledgeBase(locale: $locale) {
            translation(locale: $locale) { title }
            currentLocale(locale: $locale) { systemLocale { locale } }
          }
        }
      GQL
    end

    let(:variables) { { locale: 'not-configured' } }

    context 'with a user preferring one of its locales', authenticated_as: :agent do
      let(:agent) do
        create(:agent, preferences: { locale: alternative_locale.system_locale.locale })
      end

      before do
        create(:knowledge_base_translation, knowledge_base:, kb_locale: alternative_locale,
                                            title: 'Pavadinimas lietuviškai')
        gql.execute(query, variables:)
      end

      it 'answers in the locale the query fell back to', :aggregate_failures do
        expect(gql.result.data.dig('currentLocale', 'systemLocale', 'locale'))
          .to eq(alternative_locale.system_locale.locale)
        expect(gql.result.data.dig('translation', 'title')).to eq('Pavadinimas lietuviškai')
      end
    end
  end
end

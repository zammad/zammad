# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::KnowledgeBase::AnswerUpdates, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:answer)       { published_answer }
  let(:variables)    { { answerId: gql.id(answer) } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~QUERY
      subscription knowledgeBaseAnswerUpdates($answerId: ID!, $locale: String, $initial: Boolean = false) {
        knowledgeBaseAnswerUpdates(answerId: $answerId, locale: $locale, initial: $initial) {
          answer {
            title
          }
        }
      }
    QUERY
  end

  before do
    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  shared_examples 'subscribes and receives updates' do
    it 'subscribes' do
      expect(gql.result.data).to eq({ 'answer' => nil })
    end

    context 'with initial data' do
      let(:variables) { { answerId: gql.id(answer), initial: true } }

      it 'subscribes with initial data' do
        expect(gql.result.data[:answer][:title]).to eq(answer.translation_primary.title)
      end
    end

    it 'receives updates when the answer translation is edited' do
      answer.translation_primary.update!(title: 'A brand new title')

      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'knowledgeBaseAnswerUpdates', 'answer', 'title')).to eq('A brand new title')
    end
  end

  context 'with an admin (editor)', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    include_examples 'subscribes and receives updates'

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'with an agent (reader)', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    include_examples 'subscribes and receives updates'

    context 'with a draft answer' do
      let(:answer) { draft_answer }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'with a customer', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    include_examples 'subscribes and receives updates'

    it 'reports not found when the knowledge base becomes inactive' do
      knowledge_base.update!(active: false)
      answer.touch

      expect(mock_channel.mock_broadcasted_first.error_type).to eq(ActiveRecord::RecordNotFound)
    end

    context 'with a draft answer' do
      let(:answer) { draft_answer }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'when the knowledge base is inactive', authenticated_as: :customer do
    let(:customer)       { create(:customer) }
    let(:knowledge_base) { create(:knowledge_base, active: false) }
    let(:variables)      { { answerId: gql.id(answer), initial: true } }

    it 'is not found' do
      expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
    end
  end

  context 'when the answer is not translated to the browsed locale' do
    let(:variables) do
      {
        answerId: gql.id(answer),
        locale:   alternative_locale.system_locale.locale,
        initial:  true,
      }
    end

    context 'with an admin (editor)', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'subscribes with the fallback translation' do
        expect(gql.result.data[:answer][:title]).to eq(answer.translation_primary.title)
      end
    end

    context 'with an agent (reader)', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end

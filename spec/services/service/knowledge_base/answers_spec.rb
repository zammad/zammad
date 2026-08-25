# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Answers do
  subject(:answers) do
    described_class.with_current_user(user).execute(category:, locale:)
  end

  include_context 'basic Knowledge Base'

  let(:user)   { create(:admin) }
  let(:locale) { primary_locale }

  before do
    published_answer
    internal_answer
    draft_answer
    archived_answer
  end

  context 'with an editor' do
    let(:user) { create(:admin) }

    it 'returns published, internal, draft and archived answers' do
      expect(answers).to contain_exactly(published_answer, internal_answer, draft_answer, archived_answer)
    end
  end

  context 'with a reader' do
    let(:user) { create(:agent) }

    it 'returns internal and published answers only' do
      expect(answers).to contain_exactly(published_answer, internal_answer)
    end
  end

  context 'with a public user' do
    let(:user) { create(:customer) }

    it 'returns published answers only' do
      expect(answers).to contain_exactly(published_answer)
    end
  end

  it 'lists the answers of the given category only' do
    expect(answers).not_to include(published_answer_in_other_category)
  end

  # Positions are not unique-constrained, so the id breaks the tie deterministically.
  context 'with answers sharing a position' do
    let(:user) { create(:admin) }

    before { KnowledgeBase::Answer.update_all(position: 1) }

    it 'orders them by position and then by id' do
      expect(answers.map(&:id)).to eq(answers.map(&:id).sort)
    end
  end

  # Mirrors the agent app: non-editors only see answers translated to the browsed locale, editors
  #   also see untranslated ones (their title falls back).
  context 'with an answer not translated to the browsed locale' do
    let(:untranslated_answer) do
      create(:knowledge_base_answer, :internal, category:, translation_attributes: { kb_locale: alternative_locale })
    end

    before { untranslated_answer }

    context 'with a reader' do
      let(:user) { create(:agent) }

      it 'hides the untranslated answer' do
        expect(answers).not_to include(untranslated_answer)
      end
    end

    context 'with an editor' do
      let(:user) { create(:admin) }

      it 'shows the untranslated answer' do
        expect(answers).to include(untranslated_answer)
      end
    end
  end

  # Usable without a user at all, which is what the public help site browses with.
  context 'without a current user' do
    subject(:answers) { described_class.execute(category:, locale:) }

    it 'returns the published answers' do
      expect(answers).to contain_exactly(published_answer)
    end
  end
end

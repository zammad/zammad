# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe KnowledgeBase::Answer::TranslationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { create(:knowledge_base_answer_translation) }
  let(:user)   { create(:user) }

  describe '#show?' do
    it 'relays to KnowledgeBase::Answer policy' do
      allow_any_instance_of(KnowledgeBase::AnswerPolicy).to receive(:show?).and_return(:expected_value)

      expect(policy.show?).to eq :expected_value
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe KnowledgeBase::Answer::Translation::ContentPolicy do
  subject(:policy) { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record) { answer.translation.content }

  context 'without user' do
    let(:user) { nil }

    context 'with a public answer' do
      let(:answer) { published_answer }

      it { is_expected.to permit_actions :show }
      it { is_expected.to forbid_actions :destroy }
    end

    context 'with a non public answer' do
      let(:answer) { internal_answer }

      it { is_expected.to forbid_actions :show, :destroy }
    end
  end

  context 'with kb editor' do
    let(:user) { create(:admin) }

    context 'with an internal answer' do
      let(:answer) { internal_answer }

      it { is_expected.to permit_actions :show, :destroy }
    end

    context 'with a draft answer' do
      let(:answer) { draft_answer }

      it { is_expected.to permit_actions :show, :destroy }
    end
  end

  context 'with kb reader' do
    let(:user) { create(:agent) }

    context 'with an internal answer' do
      let(:answer) { internal_answer }

      it { is_expected.to permit_action :show }
      it { is_expected.to forbid_action :destroy }
    end

    context 'with a draft answer' do
      let(:answer) { draft_answer }

      it { is_expected.to forbid_actions :show, :destroy }
    end
  end
end

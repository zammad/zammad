# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::KnowledgeBase::Answer::AttachmentsControllerPolicy do
  subject { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { KnowledgeBase::Answer::AttachmentsController }
  let(:params)       { { answer_id: internal_answer.id } }

  let(:record) do
    rec        = record_class.new
    rec.params = params

    rec
  end

  context 'when user has no access to the answer' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_all_actions }
  end

  context 'when user has read access to the answer' do
    let(:user) { create(:agent) }

    it { is_expected.to permit_only_actions :clone_to_form }
  end

  context 'when user has write access to the answer' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_all_actions }
  end
end

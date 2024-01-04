# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::AttachmentsControllerPolicy do
  subject { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { AttachmentsController }
  let(:object)       { create(:knowledge_base_answer, visibility, :with_attachment, category: category) }
  let(:params)       { { id: object.attachments.first.id } }
  let(:session)      { {} }

  let(:record) do
    rec             = record_class.new
    # rec.action_name = action_name
    rec.params      = params

    rec
  end

  before do
    allow(record).to receive(:session).and_return(session)
  end

  context 'with no user' do
    let(:user) { nil }

    context 'with published object' do
      let(:visibility) { :published }

      it { is_expected.to permit_actions :show }
      it { is_expected.to forbid_actions :destroy }
    end

    context 'with private object' do
      let(:visibility) { :internal }

      it { is_expected.to forbid_actions :show, :destroy }
    end
  end

  context 'with a user' do
    context 'with full access' do
      let(:user)       { create(:admin) }
      let(:visibility) { :published }

      it { is_expected.to permit_actions :show, :destroy }
    end

    context 'with limited access' do
      let(:user) { create(:agent) }
      let(:visibility) { :internal }

      it { is_expected.to permit_actions :show }
      it { is_expected.to forbid_actions :destroy }
    end

    context 'with no access' do
      let(:user) { create(:agent) }
      let(:visibility) { :draft }

      it { is_expected.to forbid_actions :show, :destroy }
    end

    context 'with object that does not have a policy' do
      let(:file) { create(:store, object: 'NonExistingObject') }
      let(:params) { { id: file.id } }
      let(:user)   { create(:admin) }

      it { is_expected.to forbid_actions :show, :destroy }
    end
  end

  context 'with a preview token' do
    let(:user)       { false }
    let(:visibility) { :draft }
    let(:session)    { { kb_preview_token: token } }

    context 'when token is valid' do
      let(:token) { Token.renew_token! 'KnowledgeBasePreview', create(:admin).id }

      it { is_expected.to permit_actions :show }
      it { is_expected.to forbid_actions :destroy }
    end

    context 'when token user does not have access' do
      let(:token) { Token.renew_token! 'KnowledgeBasePreview', create(:customer).id }

      it { is_expected.to forbid_actions :show, :destroy }
    end
  end
end

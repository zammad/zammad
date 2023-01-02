# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::TagsControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { TagsController }

  let(:record) do
    rec        = record_class.new
    rec.params = params
    rec
  end

  context 'with ticket' do
    let(:ticket) { create(:ticket) }

    let(:params) do
      {
        object: 'Ticket',
        o_id:   ticket.id,
      }
    end

    context 'when user has edit permission' do
      let(:user) { create(:agent, groups: [ticket.group]) }

      it { is_expected.to permit_actions(%i[add remove]) }
    end

    context 'when user has no edit permission' do
      let(:user) { create(:agent) }

      it { is_expected.to forbid_actions(%i[add remove]) }
    end

    context 'when user has no edit permission on this ticket' do
      let(:user) { create(:agent) }

      before do
        user.user_groups.create! group: ticket.group, access: 'read'
      end

      it { is_expected.to forbid_actions(%i[add remove]) }
    end

    context 'when user is customer' do
      let(:user) { ticket.customer }

      it { is_expected.to forbid_actions(%i[add remove]) }
    end
  end

  context 'with knowledge base answer' do
    let(:kb_answer) { create(:knowledge_base_answer) }

    let(:params) do
      {
        object: 'KnowledgeBase::Answer',
        o_id:   kb_answer.id,
      }
    end

    context 'when user has edit permission' do
      let(:role) { create(:role, permission_names: %w[knowledge_base.editor]) }
      let(:user) { create(:agent, roles: [role]) }

      it { is_expected.to permit_actions(%i[add remove]) }
    end

    context 'when user has no edit permission' do
      let(:user) { create(:agent) }

      it { is_expected.to forbid_actions(%i[add remove]) }
    end

    context 'when user is customer' do
      let(:user) { create(:customer) }

      it { is_expected.to forbid_actions(%i[add remove]) }
    end
  end

end

# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::TagsControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { TagsController }

  context 'with ticket' do
    let(:ticket) { create(:ticket) }

    let(:record) do
      rec             = record_class.new
      rec.action_name = action_name
      rec.params      = {
        object: 'Ticket',
        o_id:   ticket.id,
      }

      rec
    end

    shared_examples 'basic checks' do
      context 'when user has edit permission' do
        let(:user) { create(:agent, groups: [ticket.group]) }

        it { is_expected.to permit_action(action_name) }
      end

      context 'when user has no edit permission' do
        let(:user) { create(:agent) }

        it { is_expected.to forbid_action(action_name) }
      end
    end

    describe '#add?' do
      let(:action_name) { :add }

      include_examples 'basic checks'
    end

    describe '#remove?' do
      let(:action_name) { :remove }

      include_examples 'basic checks'
    end
  end

  context 'with knowledge base answer' do
    let(:kb_answer) { create(:knowledge_base_answer) }

    let(:record) do
      rec             = record_class.new
      rec.action_name = action_name
      rec.params      = {
        object: 'KnowledgeBase::Answer',
        o_id:   kb_answer.id,
      }

      rec
    end

    shared_examples 'basic checks' do
      context 'when user has edit permission' do
        let(:role) { create(:role, permission_names: %w[knowledge_base.editor]) }
        let(:user) { create(:agent, roles: [role]) }

        it { is_expected.to permit_action(action_name) }
      end

      context 'when user has no edit permission' do
        let(:user) { create(:agent) }

        it { is_expected.to forbid_action(action_name) }
      end
    end

    describe '#add?' do
      let(:action_name) { :add }

      include_examples 'basic checks'
    end

    describe '#remove?' do
      let(:action_name) { :remove }

      include_examples 'basic checks'
    end
  end

end

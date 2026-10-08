# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::LinksControllerPolicy do
  subject { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { LinksController }
  let(:record) do
    rec             = record_class.new
    rec.action_name = action_name
    rec.params      = params

    rec
  end

  describe '#index' do
    let(:action_name) { :index }
    let(:params) do
      {
        link_object:       link_object,
        link_object_value: link_object_value,
        action:            action_name.to_s
      }
    end

    context 'with ticket' do
      let(:ticket)            { create(:ticket) }
      let(:link_object)       { 'Ticket' }
      let(:link_object_value) { ticket.id }

      context 'when user has read access on the queried ticket' do
        let(:user) { create(:agent, groups: [ticket.group]) }

        it { is_expected.to permit_action(action_name) }
      end

      context 'when user has no access on the queried ticket' do
        let(:user) { create(:agent) }

        it { is_expected.to forbid_action(action_name) }
      end

      context 'when user is the customer of the queried ticket' do
        let(:user)   { create(:customer) }
        let(:ticket) { create(:ticket, customer: user) }

        it { is_expected.to forbid_action(action_name) }
      end

      context 'when user is the customer of an unrelated ticket' do
        let(:user) { create(:customer) }

        before { create(:link, from: ticket, to: create(:ticket, customer: user)) }

        it { is_expected.to forbid_action(action_name) }
      end

      context 'when the queried ticket does not exist' do
        let(:user)              { create(:agent) }
        let(:link_object_value) { 99_999_999 }

        it { is_expected.to forbid_action(action_name) }
      end
    end

    context 'with knowledge base answer' do
      let(:link_object)       { 'KnowledgeBase::Answer::Translation' }
      let(:link_object_value) { kb_answer.id }
      let(:role)              { create(:role, permission_names: %w[knowledge_base.reader]) }
      let(:user)              { create(:agent, roles: [role]) }

      context 'when the answer is visible to the user' do
        let(:kb_answer) { published_answer.translations.first }

        it { is_expected.to permit_action(action_name) }
      end

      context 'when the answer is not visible to the user' do
        let(:kb_answer) { archived_answer.translations.first }

        it { is_expected.to forbid_action(action_name) }
      end

      context 'when the answer translation does not exist' do
        let(:link_object_value) { 99_999_999 }

        it { is_expected.to forbid_action(action_name) }
      end
    end

    context 'with an unsupported link object' do
      let(:user)              { create(:admin) }
      let(:link_object)       { 'Announcement' }
      let(:link_object_value) { 1 }

      it { is_expected.to forbid_action(action_name) }
    end

    context 'without a link object' do
      let(:user)   { create(:admin) }
      let(:params) { { action: action_name.to_s } }

      it { is_expected.to forbid_action(action_name) }
    end
  end

  describe '#add' do
    context 'with target ticket and source ticket' do
      let(:ticket_source) { create(:ticket) }
      let(:ticket_target) { create(:ticket) }
      let(:action_name)   { :add }
      let(:params) do
        {
          link_object_source:        'Ticket',
          link_object_source_number: ticket_source.number,
          link_object_target:        'Ticket',
          link_object_target_value:  ticket_target.id,
          action:                    action_name.to_s
        }
      end

      context 'when user has full permission on target and access on source' do
        let(:user) { create(:agent, groups: [ticket_target.group, ticket_source.group]) }

        it { is_expected.to permit_action(action_name) }
      end

      context 'when user has no permission on target' do
        let(:user) { create(:agent, groups: [ticket_source.group]) }

        it { is_expected.to forbid_action(action_name) }
      end

      context 'when user has no permission on source' do
        let(:user) { create(:agent, groups: [ticket_target.group]) }

        it { is_expected.to forbid_action(action_name) }
      end
    end

    context 'with target ticket and source knowledge base answer' do
      let(:ticket_target) { create(:ticket) }
      let(:action_name)   { :add }
      let(:params) do
        {
          link_object_source:        'KnowledgeBase::Answer::Translation',
          link_object_source_number: kb_answer_source.id,
          link_object_target:        'Ticket',
          link_object_target_value:  ticket_target.id,
          action:                    action_name.to_s
        }
      end

      context 'when user has full permission on target and accces on source' do
        let(:kb_answer_source) { published_answer.translations.first }
        let(:user)             { create(:agent, groups: [ticket_target.group]) }

        it { is_expected.to permit_action(action_name) }
      end

      context 'when user has no permission on target' do
        let(:kb_answer_source) { published_answer.translations.first }
        let(:user)             { create(:agent) }

        it { is_expected.to forbid_action(action_name) }
      end

      context 'when user has no access on source' do
        let(:kb_answer_source) { archived_answer.translations.first }
        let(:user)             { create(:agent, groups: [ticket_target.group]) }

        it { is_expected.to forbid_action(action_name) }
      end
    end

    context 'with target knowledge base answer and source ticket' do
      let(:ticket_source)    { create(:ticket) }
      let(:kb_answer_target) { internal_answer.translations.first }
      let(:action_name)      { :add }
      let(:params) do
        {
          link_object_source:        'Ticket',
          link_object_source_number: ticket_source.number,
          link_object_target:        'KnowledgeBase::Answer::Translation',
          link_object_target_value:  kb_answer_target.id,
        }
      end

      context 'when user has full permission on target and accces on source' do
        let(:role) { create(:role, permission_names: %w[knowledge_base.editor ticket.agent]) }
        let(:user) { create(:agent, groups: [ticket_source.group], roles: [role]) }

        it { is_expected.to permit_action(action_name) }
      end

      context 'when user has no permission on target' do
        let(:role) { create(:role, permission_names: %w[ticket.agent]) }
        let(:user) { create(:user, groups: [ticket_source.group], roles: [role]) }

        it { is_expected.to forbid_action(action_name) }
      end

      context 'when user has no accces on source' do
        let(:role)          { create(:role, permission_names: %w[knowledge_base.editor ticket.agent]) }
        let(:ticket_source) { create(:ticket, group: create(:group)) }
        let(:user)          { create(:agent, roles: [role]) }

        it { is_expected.to forbid_action(action_name) }
      end
    end
  end

  describe '#remove' do
    context 'with target ticket and source ticket' do
      let(:ticket_source) { create(:ticket) }
      let(:ticket_target) { create(:ticket) }
      let(:action_name)   { :remove }
      let(:params) do
        {
          link_object_source:       'Ticket',
          link_object_source_value: ticket_source.id,
          link_object_target:       'Ticket',
          link_object_target_value: ticket_target.id,
          action:                   action_name.to_s
        }
      end

      context 'when user has full permission on target and access on source' do
        let(:user) { create(:agent, groups: [ticket_target.group, ticket_source.group]) }

        it { is_expected.to permit_action(action_name) }
      end

      context 'when user has no permission on target' do
        let(:user) { create(:agent, groups: [ticket_source.group]) }

        it { is_expected.to forbid_action(action_name) }
      end

      context 'when user has no permission on source' do
        let(:user) { create(:agent, groups: [ticket_target.group]) }

        it { is_expected.to permit_action(action_name) }
      end
    end

    context 'with target ticket and source knowledge base answer' do
      let(:ticket_target) { create(:ticket) }
      let(:action_name)   { :remove }
      let(:params) do
        {
          link_object_source:       'KnowledgeBase::Answer::Translation',
          link_object_source_value: kb_answer_source.id,
          link_object_target:       'Ticket',
          link_object_target_value: ticket_target.id,
          action:                   action_name.to_s
        }
      end

      context 'when user has full permission on target and access on source' do
        let(:kb_answer_source) { published_answer.translations.first }
        let(:user) { create(:agent, groups: [ticket_target.group]) }

        it { is_expected.to permit_action(action_name) }
      end

      context 'when user has no permission on target' do
        let(:kb_answer_source) { published_answer.translations.first }
        let(:user) { create(:agent) }

        it { is_expected.to forbid_action(action_name) }
      end

      context 'when user has no permission on source' do
        let(:kb_answer_source) { archived_answer.translations.first }
        let(:user) { create(:agent, groups: [ticket_target.group]) }

        it { is_expected.to permit_action(action_name) }
      end
    end

    context 'with target knowledge base answer and source ticket' do
      let(:ticket_source)    { create(:ticket) }
      let(:kb_answer_target) { internal_answer.translations.first }
      let(:action_name)      { :remove }
      let(:params) do
        {
          link_object_source:        'Ticket',
          link_object_source_number: ticket_source.number,
          link_object_target:        'KnowledgeBase::Answer::Translation',
          link_object_target_value:  kb_answer_target.id,
        }
      end

      context 'when user has full permission on target and accces on source' do
        let(:role) { create(:role, permission_names: %w[knowledge_base.editor]) }
        let(:user) { create(:agent, groups: [ticket_source.group], roles: [role]) }

        it { is_expected.to permit_action(action_name) }
      end

      context 'when user has no permission on target' do
        let(:role) { create(:role, permission_names: %w[ticket.agent]) }
        let(:user) { create(:user, groups: [ticket_source.group], roles: [role]) }

        it { is_expected.to forbid_action(action_name) }
      end

      context 'when user has no accces on source' do
        let(:role)          { create(:role, permission_names: %w[knowledge_base.editor]) }
        let(:ticket_source) { create(:ticket, group: create(:group)) }
        let(:user)          { create(:agent, roles: [role]) }

        it { is_expected.to permit_action(action_name) }
      end
    end
  end
end

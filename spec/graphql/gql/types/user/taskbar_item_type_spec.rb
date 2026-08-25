# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::User::TaskbarItemType, :aggregate_failures do
  let(:user)  { create(:agent, groups: [Group.first]) }
  let(:owner) { user }
  let(:key) do
    entity = create(:ticket, owner:, group: Group.first)

    "#{entity.class.name}-#{entity.id}"
  end
  let(:taskbar)  { create(:taskbar, user_id: user.id, key:) }
  let(:instance) { described_class.send(:new, taskbar, Hashie::Mash.new({ current_user: user })) }

  describe 'field: entity' do

    context 'when entity is found and user has access' do
      it 'returns the entity as well as an appropriate access information' do
        expect(instance.entity).to be_a(Ticket)
        expect(instance.entity_access).to eq('Granted')
      end
    end

    context 'when entity is not found' do
      it 'returns nil as well as an appropriate access information' do
        taskbar.update!(key: 'Ticket-0')

        expect(instance.entity).to be_nil
        expect(instance.entity_access).to eq('NotFound')
      end
    end

    context 'when entity is found but user has no access' do
      let(:user) { create(:agent, groups: []) }

      it 'returns nil as well as an appropriate access information' do
        expect(instance.entity).to be_nil
        expect(instance.entity_access).to eq('Forbidden')
      end
    end

    context 'when entity is not instanciable' do
      it 'returns nil as well as an appropriate access information' do
        taskbar.update!(key: 'Unknown-0')

        expect(instance.entity).to be_nil
        expect(instance.entity_access).to be_nil
      end
    end

    context 'when entity is a ticket create screen' do
      let(:key) { 'TicketCreateScreen-4711' }

      it 'returns the state as entity' do
        taskbar.update!(state: { 'title' => 'Ticket Title', 'formSenderType' => 'email-out' })

        expect(instance.entity).to include('title' => 'Ticket Title', 'formSenderType' => 'email-out')
      end
    end

    context 'when entity is a knowledge base answer create screen' do
      let(:uid) { SecureRandom.uuid }
      let(:key) { "KnowledgeBaseAnswerCreateScreen-#{uid}" }

      it 'returns state and params as entity, with the tab id as uid' do
        taskbar.update!(state: { 'title' => 'Answer Title' }, params: { 'locale' => 'de-de' })

        expect(instance.entity).to include('title' => 'Answer Title', 'locale' => 'de-de', uid: uid, type: 'KnowledgeBaseAnswerCreate')
      end

      # The tab of a draft nothing was typed into yet, which must not look like a missing record.
      it 'returns the entity without a title' do
        taskbar.update!(state: {}, params: {})

        # The state is stored with indifferent access, so the merged keys come back as strings.
        expect(instance.entity).to eq({ 'uid' => uid, 'type' => 'KnowledgeBaseAnswerCreate' })
      end
    end

    # The key of an answer *record*, which the edit view will use, must keep resolving to the
    #   model - the create screen key above must not swallow it.
    context 'when entity is a knowledge base answer' do
      let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
      let(:user)        { create(:user, roles: [editor_role]) }
      let(:answer)      { create(:knowledge_base_answer) }
      let(:key)         { "KnowledgeBase__Answer-#{answer.id}" }

      it 'returns the answer' do
        expect(instance.entity).to eq(answer)
        expect(instance.entity_access).to eq('Granted')
      end
    end
  end
end

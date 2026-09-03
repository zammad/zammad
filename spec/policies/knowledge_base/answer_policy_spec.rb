# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'policies/knowledge_base_policy_examples'

describe KnowledgeBase::AnswerPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { create(:knowledge_base_answer) }
  let(:user)   { create(:user) }

  shared_context 'with answer visibility' do |visible:, visible_internally:|
    before do
      allow(record).to receive_messages(visible?: visible, visible_internally?: visible_internally)
    end
  end

  describe '#show?' do
    let(:editorial_fields) { %i[internal_at archived_at edited_at edited_by created_by updated_by] }

    def mock_access(access)
      allow(policy).to receive(:access).and_return(access)
    end

    context 'when visible and visible internally' do
      include_examples 'with answer visibility', visible: true, visible_internally: true

      it 'returns true if editor' do
        mock_access 'editor'

        expect(policy.show?).to be true
      end

      it 'returns true if reader' do
        mock_access 'reader'

        expect(policy.show?).to be true
      end

      # Published content is public; the editorial lifecycle around it is not.
      it 'returns a field scope without the editorial fields if none' do
        mock_access 'none'

        expect(policy.show?)
          .to permit_fields(%i[title content published_at])
          .and forbid_fields(editorial_fields)
      end
    end

    context 'when visible internally only' do
      include_examples 'with answer visibility', visible: false, visible_internally: true
      include_examples 'with KB policy check', editor: true, reader: true, none: false, method: :show?
    end

    context 'when not visible' do
      include_examples 'with answer visibility', visible: false, visible_internally: false
      include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :show?
    end
  end

  # https://github.com/zammad/zammad/issues/6338
  describe 'with an inactive knowledge base' do
    before { record.category.knowledge_base.update! active: false }

    describe '#show?' do
      include_examples 'with KB policy check', editor: false, reader: false, none: false, method: :show?
    end

    describe '#show_public?' do
      include_examples 'with KB policy check', editor: false, reader: false, none: false, method: :show_public?
    end
  end

  describe '#show_public?' do
    context 'when visible and visible internally' do
      include_examples 'with answer visibility', visible: true, visible_internally: true
      include_examples 'with KB policy check', editor: true, reader: true, none: true, method: :show_public?
    end

    context 'when visible internally only' do
      include_examples 'with answer visibility', visible: false, visible_internally: true
      include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :show_public?
    end

    context 'when not visible' do
      include_examples 'with answer visibility', visible: false, visible_internally: false
      include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :show_public?
    end
  end

  describe '#update?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :update?
  end

  describe '#create?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :create?
  end

  describe '#destroy?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :destroy?
  end
end

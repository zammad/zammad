# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::TextToolPolicy::Scope do
  subject(:scope) { described_class.new(user, original_collection) }

  let(:original_collection) { AI::TextTool }

  let(:group_a) { create(:group) }
  let(:ai_text_tool_a) { create(:ai_text_tool, groups: [group_a]) }
  let(:group_b)        { create(:group) }
  let(:ai_text_tool_b) { create(:ai_text_tool, groups: [group_b]) }
  let(:ai_text_tool_c) { create(:ai_text_tool, groups: []) }

  before do
    AI::TextTool.destroy_all
    ai_text_tool_a && ai_text_tool_b && ai_text_tool_c
  end

  describe '#resolve' do
    context 'without user' do
      let(:user) { nil }

      it 'throws exception' do
        expect { scope.resolve }.to raise_error %r{Authentication required}
      end
    end

    context 'with customer' do
      let(:user) { create(:customer) }

      it 'returns empty' do
        expect(scope.resolve).to be_empty
      end
    end

    context 'with agent' do
      let(:user) { create(:agent) }

      before { user.groups << group_a }

      it 'returns global and group ai_text_tool' do
        expect(scope.resolve).to contain_exactly(ai_text_tool_a, ai_text_tool_c)
      end

      context 'when using default context' do
        it 'calls available_in_groups with change and create' do
          allow(user).to receive(:group_ids_access).and_call_original

          scope.resolve

          expect(user).to have_received(:group_ids_access).with(%i[change create])
        end
      end

      context 'when using custom context' do
        it 'forwards custom context to available_in_groups' do
          allow(user).to receive(:group_ids_access).and_call_original

          scope.resolve(context: :custom)

          expect(user).to have_received(:group_ids_access).with(:custom)
        end
      end
    end

    context 'with admin' do
      let(:user) { create(:admin) }

      before { user.groups << group_b }

      it 'returns all ai_text_tools' do
        expect(scope.resolve).to contain_exactly(ai_text_tool_a, ai_text_tool_b, ai_text_tool_c)
      end
    end
  end
end

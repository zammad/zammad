# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TextModulePolicy::Scope do
  subject(:scope) { described_class.new(user, original_collection) }

  let(:original_collection) { TextModule }

  let(:group_a) { create(:group) }
  let(:text_module_a) { create(:text_module, groups: [group_a]) }
  let(:group_b)       { create(:group) }
  let(:text_module_b) { create(:text_module, groups: [group_b]) }
  let(:text_module_c) { create(:text_module, groups: []) }

  before do
    TextModule.destroy_all
    text_module_a && text_module_b && text_module_c
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

      it 'returns global and group text_module' do
        expect(scope.resolve).to contain_exactly(text_module_a, text_module_c)
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

      it 'returns all text_modules' do
        expect(scope.resolve).to contain_exactly(text_module_a, text_module_b, text_module_c)
      end
    end
  end
end

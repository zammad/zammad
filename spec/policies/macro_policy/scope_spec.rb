# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MacroPolicy::Scope do
  subject(:scope) { described_class.new(user, original_collection) }

  let(:original_collection) { Macro }

  let(:group_a) { create(:group) }
  let(:macro_a) { create(:macro, groups: [group_a]) }
  let(:group_b) { create(:group) }
  let(:macro_b) { create(:macro, groups: [group_b]) }
  let(:macro_c) { create(:macro, groups: []) }

  before do
    Macro.destroy_all
    macro_a && macro_b && macro_c
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

      it 'returns global and group macro' do
        expect(scope.resolve).to match_array [macro_a, macro_c]
      end
    end

    context 'with admin' do
      let(:user) { create(:admin) }

      before { user.groups << group_b }

      it 'returns all macros' do
        expect(scope.resolve).to match_array [macro_a, macro_b, macro_c]
      end
    end
  end
end

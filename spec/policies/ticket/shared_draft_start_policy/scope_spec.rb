# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::SharedDraftStartPolicy::Scope do
  subject(:scope) { described_class.new(user, original_collection) }

  let(:original_collection) { Ticket::SharedDraftStart }

  let(:group_a) { create(:group) }
  let(:draft_a) { create(:ticket_shared_draft_start, group: group_a) }
  let(:group_b) { create(:group) }
  let(:draft_b) { create(:ticket_shared_draft_start, group: group_b) }

  before do
    draft_a && draft_b
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

      it 'returns group a' do
        expect(scope.resolve).to match_array [draft_a]
      end
    end
  end
end

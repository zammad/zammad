# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Macro, type: :model do
  it_behaves_like 'HasCollectionUpdate', collection_factory: :macro
  it_behaves_like 'HasXssSanitizedNote', model_factory: :macro

  describe 'validation' do
    it 'uses Validations::VerifyPerformRulesValidator' do
      expect(described_class).to have_validator(Validations::VerifyPerformRulesValidator).on(:perform)
    end
  end

  describe 'Instance methods:' do
    describe '#applicable_on?' do
      let(:ticket)   { create(:ticket) }
      let(:ticket_a) { create(:ticket, group: group_a) }
      let(:ticket_b) { create(:ticket, group: group_b) }
      let(:ticket_c) { create(:ticket, group: group_c) }
      let(:group_a)  { create(:group) }
      let(:group_b)  { create(:group) }
      let(:group_c)  { create(:group) }

      context 'when macro has no groups' do
        subject(:macro) { create(:macro, groups: []) }

        it 'return true for a single group' do
          expect(macro).to be_applicable_on(ticket)
        end

        it 'return true for multiple tickets' do
          expect(macro).to be_applicable_on([ticket, ticket_a, ticket_b])
        end
      end

      context 'when macro has a single group' do
        subject(:macro) { create(:macro, groups: [group_a]) }

        it 'returns true if macro group matches ticket' do
          expect(macro).to be_applicable_on(ticket_a)
        end

        it 'returns false if macro group does not match ticket' do
          expect(macro).not_to be_applicable_on(ticket_b)
        end

        it 'returns false if macro group match a ticket and not the other' do
          expect(macro).not_to be_applicable_on([ticket_a, ticket_b])
        end
      end

      context 'when macro has multiple groups' do
        subject(:macro) { create(:macro, groups: [group_a, group_c]) }

        it 'returns true if macro groups include ticket group' do
          expect(macro).to be_applicable_on(ticket_a)
        end

        it 'returns false if macro groups do not include ticket group' do
          expect(macro).not_to be_applicable_on(ticket_b)
        end

        it 'returns true if macro groups match tickets groups' do
          expect(macro).to be_applicable_on([ticket_a, ticket_c])
        end

        it 'returns false if macro groups does not match one of tickets group' do
          expect(macro).not_to be_applicable_on([ticket_a, ticket_b])
        end
      end
    end
  end
end

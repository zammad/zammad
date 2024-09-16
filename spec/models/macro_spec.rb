# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/application_model/has_cache_examples'

RSpec.describe Macro, type: :model do
  it_behaves_like 'HasCollectionUpdate', collection_factory: :macro
  it_behaves_like 'HasXssSanitizedNote', model_factory: :macro
  it_behaves_like 'Association clears cache', association: :groups

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

    describe '#performable_on?' do
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
          expect(macro).to be_performable_on(ticket, activator_type: nil)
        end

        context 'when macro is not active' do
          before { macro.update! active: false }

          it 'returns false if macro group does not match ticket' do
            expect(macro).not_to be_performable_on(ticket_b, activator_type: nil)
          end
        end
      end

      context 'when macro has a single group' do
        subject(:macro) { create(:macro, groups: [group_a]) }

        it 'returns true if macro group matches ticket' do
          expect(macro).to be_performable_on(ticket_a, activator_type: nil)
        end

        it 'returns false if macro group does not match ticket' do
          expect(macro).not_to be_performable_on(ticket_b, activator_type: nil)
        end
      end
    end
  end

  describe 'Class methods:' do
    describe '.available_in_groups' do
      let(:group) { create(:group) }
      let(:macro) { create(:macro, groups:) }

      before { macro }

      context 'when macro has a group' do
        let(:groups) { [group] }

        it 'returns macro if group matches' do
          expect(described_class.available_in_groups([group]))
            .to include(macro)
        end

        it 'returns macro if one of groups matches' do
          expect(described_class.available_in_groups([group, create(:group)]))
            .to include(macro)
        end

        it 'does not return macro if group does not match' do
          expect(described_class.available_in_groups([create(:group)]))
            .not_to include(macro)
        end

        context 'when macro is inactive' do
          before { macro.update!(active: false) }

          it 'does not return inactive macros' do
            expect(described_class.available_in_groups([group]))
              .not_to include(macro)
          end
        end
      end

      context 'when macro has multiple groups' do
        let(:groups) { [group, create(:group)] }

        it 'returns macro if one of given group matches' do
          expect(described_class.available_in_groups([group]))
            .to include(macro)
        end

        it 'returns macro if one of given groups matches' do
          expect(described_class.available_in_groups([group, create(:group)]))
            .to include(macro)
        end

        it 'does not return macro if no group matches' do
          expect(described_class.available_in_groups([create(:group)]))
            .not_to include(macro)
        end

        context 'when macro is inactive' do
          before { macro.update!(active: false) }

          it 'does not return inactive macros' do
            expect(described_class.available_in_groups([group]))
              .not_to include(macro)
          end
        end
      end

      context 'when macro has no group limitations' do
        let(:groups) { [] }

        it 'returns macro for any group' do
          expect(described_class.available_in_groups([group]))
            .to include(macro)
        end

        context 'when macro is inactive' do
          before { macro.update!(active: false) }

          it 'does not return inactive macros' do
            expect(described_class.available_in_groups([group]))
              .not_to include(macro)
          end
        end
      end
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::OverviewsPolicy::Scope do
  subject(:scope) { described_class.new(user, original_collection) }

  let(:original_collection) { Overview }

  let(:overview_a) { create(:overview) }
  let(:overview_b) { create(:overview, organization_shared: true) }
  let(:overview_c) { create(:overview, out_of_office: true) }

  before do
    Overview.destroy_all

    overview_a && overview_b && overview_c
  end

  describe '#resolve' do
    context 'without user' do
      let(:user) { nil }

      it 'throws exception' do
        expect { scope.resolve }.to raise_error %r{Authentication required}
      end
    end

    context 'with customer' do
      let(:user) { create(:customer, organization: create(:organization, shared: false)) }

      it 'returns base' do
        expect(scope.resolve).to match_array [overview_a]
      end

      context 'with shared organization' do
        before do
          user.organization.update! shared: true
        end

        it 'returns base and shared' do
          expect(scope.resolve).to match_array [overview_a, overview_b]
        end
      end
    end

    context 'with agent' do
      let(:user) { create(:agent) }

      it 'returns base' do
        expect(scope.resolve).to match_array [overview_a]
      end

      context 'when out of office replacement' do
        before do
          create(:agent).update!(
            out_of_office:                true,
            out_of_office_start_at:       1.day.ago,
            out_of_office_end_at:         1.day.from_now,
            out_of_office_replacement_id: user.id,
          )
        end

        it 'returns base and out of office' do
          expect(scope.resolve).to match_array [overview_a, overview_c]
        end
      end
    end

    context 'with agent-customer' do
      let(:user) { create(:agent_and_customer, organization: create(:organization, shared: false)) }

      it 'returns base' do
        expect(scope.resolve).to match_array [overview_a]
      end

      context 'with shared organization' do
        before do
          user.organization.update! shared: true
        end

        it 'returns base and shared' do
          expect(scope.resolve).to match_array [overview_a, overview_b]
        end

        context 'when out of office replacement' do
          before do
            create(:agent).update!(
              out_of_office:                true,
              out_of_office_start_at:       1.day.ago,
              out_of_office_end_at:         1.day.from_now,
              out_of_office_replacement_id: user.id,
            )
          end

          it 'returns all' do
            expect(scope.resolve).to match_array [overview_a, overview_b, overview_c]
          end
        end
      end

      context 'when out of office replacement' do
        before do
          create(:agent).update!(
            out_of_office:                true,
            out_of_office_start_at:       1.day.ago,
            out_of_office_end_at:         1.day.from_now,
            out_of_office_replacement_id: user.id,
          )
        end

        it 'returns base and out of office' do
          expect(scope.resolve).to match_array [overview_a, overview_c]
        end
      end
    end

    context 'without ticket permission' do
      let(:user) { create(:admin_only) }

      it 'returns nothing' do
        expect(scope.resolve).to be_empty
      end
    end
  end
end

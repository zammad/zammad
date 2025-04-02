# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe GroupPolicy::Scope do
  subject(:scope) { described_class.new(user, Group) }

  let(:groups) { create_list(:group, 3) }

  describe '#resolve' do
    context 'with customer' do
      let(:user) { create(:customer) }

      it 'does return all groups' do
        expect(scope.resolve).to include(*groups)
      end

      context 'when customer groups are set' do
        before do
          Setting.set('customer_ticket_create_group_ids', [groups.first.id])
        end

        it 'does return first group' do
          expect(scope.resolve).to include(groups[0])
        end

        it 'does not return second and third group' do
          expect(scope.resolve).not_to include(*groups[1..])
        end
      end
    end

    context 'with agent' do
      let(:user) { create(:agent) }

      it 'does return all groups' do
        expect(scope.resolve).to include(*groups)
      end

      context 'when customer groups are set' do
        before do
          Setting.set('customer_ticket_create_group_ids', [groups.first.id])
        end

        it 'does return all groups' do
          expect(scope.resolve).to include(*groups)
        end
      end
    end

    context 'with admin' do
      let(:user) { create(:admin) }

      it 'does return all groups' do
        expect(scope.resolve).to include(*groups)
      end

      context 'when customer groups are set' do
        before do
          Setting.set('customer_ticket_create_group_ids', [groups.first.id])
        end

        it 'does return all groups' do
          expect(scope.resolve).to include(*groups)
        end
      end
    end
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe GroupHierarchy, db_strategy: :reset, type: :db_migration do
  describe '#change' do
    before do
      remove_foreign_key :groups, column: :parent_id
      remove_column :groups, :parent_id
      remove_column :groups, :name_last
      change_column :groups, :name, :string, limit: 160

      Group.reset_column_information

      migrate
    end

    it 'increases limit for name column' do
      expect(Group.column_for_attribute(:name).sql_type_metadata.limit).to eq((160 * 6) + (2 * 5))
    end

    it 'adds name_last column' do
      expect(Group.column_for_attribute(:name_last).sql_type_metadata.type).to eq(:string)
    end

    it 'adds parent_id column' do
      expect(Group.column_for_attribute(:parent_id).sql_type_metadata.type).to eq(:integer)
    end
  end

  describe '#migrate_group_name' do
    context 'when group name does not contain reserved characters' do
      let(:user)  { create(:user) }
      let(:group) { create(:group, name: 'A', updated_by_id: user.id) }

      before do
        group
        described_class.new.migrate_group_name
      end

      it 'does not migrate name' do
        expect(group.reload).to have_attributes(name: 'A', name_last: 'A', updated_by_id: 1)
      end
    end

    context 'when group name contains reserved characters' do
      context 'without conflicting group names' do
        let(:group) { create(:group) }

        before do
          group.update_columns(name: 'A::B')
          described_class.new.migrate_group_name
        end

        it 'migrates name with an alternative delimiter' do
          expect(group.reload).to have_attributes(name: 'A-B', name_last: 'A-B', updated_by_id: 1)
        end
      end

      context 'with conflicting target group names' do
        let(:group1) { create(:group) }
        let(:group2) { create(:group, name: 'A-B-C') }
        let(:group3) { create(:group, name: 'A--B--C') }

        before do
          group1.update_columns(name: 'A::B::C') && group2 && group3
          described_class.new.migrate_group_name
        end

        it 'migrates name with an longer alternative delimiter' do
          expect(group1.reload).to have_attributes(name: 'A---B---C', name_last: 'A---B---C')
        end
      end
    end
  end
end

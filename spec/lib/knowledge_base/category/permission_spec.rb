# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBase::Category::Permission do
  include_context 'basic Knowledge Base'

  describe '#permissions_effective' do
    let(:child_category)    { create(:knowledge_base_category, knowledge_base: knowledge_base, parent: category) }
    let(:child_permission)  { create(:knowledge_base_permission, permissionable: child_category, access: 'reader') }
    let(:parent_permission) { create(:knowledge_base_permission, permissionable: category) }

    context 'when no permissions exist' do
      it 'parent category returns nil' do
        expect(described_class.new(category).permissions_effective).to be_blank
      end

      it 'child category returns nil' do
        expect(described_class.new(child_category).permissions_effective).to be_blank
      end
    end

    context 'when parent category has permissions' do
      before { parent_permission && child_category }

      it 'parent category returns parent permission' do
        expect(described_class.new(category).permissions_effective).to eq [parent_permission]
      end

      it 'child category returns parent permission' do
        expect(described_class.new(child_category).permissions_effective).to eq [parent_permission]
      end
    end

    context 'when child category has permissions' do
      before { child_permission }

      it 'parent category returns parent permission' do
        expect(described_class.new(category).permissions_effective).to be_blank
      end

      it 'child category returns parent permission' do
        expect(described_class.new(child_category).permissions_effective).to eq [child_permission]
      end
    end

    context 'when both parent and child categories have permissions' do
      before { child_permission && parent_permission }

      it 'parent category returns parent permission' do
        expect(described_class.new(category).permissions_effective).to eq [parent_permission]
      end

      it 'child category returns parent permission' do
        expect(described_class.new(child_category).permissions_effective).to eq [child_permission, parent_permission]
      end
    end

    context 'when both parent child categories have colliding permissions for the same role' do
      let(:child_permission_on_same_role) { create(:knowledge_base_permission, permissionable: child_category, access: 'reader', role: parent_permission.role) }

      before { parent_permission && child_permission && child_permission_on_same_role }

      it 'parent category returns parent permission' do
        expect(described_class.new(category).permissions_effective).to eq [parent_permission]
      end

      it 'child category returns child permission override' do
        expect(described_class.new(child_category).permissions_effective).to eq [child_permission, child_permission_on_same_role]
      end
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe CoreWorkflow::Custom::AdminGroupParentId, mariadb: true, type: :model do
  include_context 'with core workflow base'

  context 'when editing an existing group' do
    let(:group) { create(:group) }
    let(:payload) do
      base_payload.merge(
        'screen'     => 'edit',
        'class_name' => 'Group',
        'params'     => { 'id' => group.id.to_s },
      )
    end

    it 'filters out current group' do
      expect(result[:restrict_values]).to include(
        'parent_id' => not_include(group.id.to_s)
      )
    end

    context 'with existing child groups' do
      let!(:child_group1) { create(:group, parent: group) }
      let!(:child_group2) { create(:group, parent: group) }

      it 'filters out child groups' do
        expect(result[:restrict_values]).to include(
          'parent_id' => not_include(child_group1.id.to_s, child_group2.id.to_s)
        )
      end
    end
  end

  context 'when creating a new group' do
    let!(:group) { create(:group) }
    let(:payload) do
      base_payload.merge(
        'screen'     => 'create',
        'class_name' => 'Group',
      )
    end

    it 'does not filter out existing group' do
      expect(result[:restrict_values]).to include(
        'parent_id' => include(group.id.to_s)
      )
    end
  end
end

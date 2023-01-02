# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_group_relation_definition_examples'

RSpec.describe RoleGroup do

  let!(:group_relation_instance) { create(:role) }

  it_behaves_like 'HasGroupRelationDefinition'

  it 'prevents roles from beeing in Group assets' do

    group = create(:group)

    described_class.create!(
      group: group,
      role:  create(:role)
    )
    expect(group.assets({})[:Group][group.id]).not_to include('role_ids')
  end

end

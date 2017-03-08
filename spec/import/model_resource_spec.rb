require 'rails_helper'

RSpec.describe Import::ModelResource do

  before do
    module Import
      module Test
        class Group < Import::ModelResource
        end
      end
    end
  end

  it 'creates model Objects by class name' do

    group_data = attributes_for(:group)

    expect {
      Import::Test::Group.new(group_data)
    }.to change { Group.count }.by(1)
  end

  it 'updates model Objects by class name' do

    group = create(:group)

    update_attributes        = group.serializable_hash
    update_attributes[:note] = 'Updated'

    expect {
      Import::Test::Group.new(update_attributes)
      group.reload
    }.to change { group.note }
  end
end

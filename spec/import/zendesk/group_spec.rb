require 'rails_helper'

RSpec.describe Import::Zendesk::Group do

  it 'creates a group if not exists' do

    group = double(
      id:      31_337,
      name:    'Test Group',
      deleted: true
    )

    local_group = instance_double(::Group, id: 1337)

    expect(::Group).to receive(:create_if_not_exists).with(hash_including(name: group.name, active: !group.deleted)).and_return(local_group)

    created_instance = described_class.new(group)

    expect(created_instance).to respond_to(:id)
    expect(created_instance.id).to eq(local_group.id)

    expect(created_instance).to respond_to(:zendesk_id)
    expect(created_instance.zendesk_id).to eq(group.id)
  end
end

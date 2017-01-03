require 'rails_helper'

RSpec.describe Import::Zendesk::Organization do

  it 'creates a organization if not exists' do

    organization = double(
      id:                  31_337,
      name:                'Test Organization',
      note:                'Test Organization note',
      shared_tickets:      true,
      organization_fields: nil
    )

    local_organization = instance_double(::Organization, id: 1337)

    expect(::Organization).to receive(:create_if_not_exists).with(hash_including(name: organization.name, note: organization.note, shared: organization.shared_tickets)).and_return(local_organization)

    created_instance = described_class.new(organization)

    expect(created_instance).to respond_to(:id)
    expect(created_instance).to respond_to(:zendesk_id)

    expect(created_instance.id).to eq(local_organization.id)
    expect(created_instance.zendesk_id).to eq(organization.id)
  end
end

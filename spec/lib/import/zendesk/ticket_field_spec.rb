require 'rails_helper'
require 'lib/import/zendesk/object_field_examples'

RSpec.describe Import::Zendesk::TicketField do
  it_behaves_like 'Import::Zendesk::ObjectField'

  it 'handles fields with dashes in title' do

    zendesk_object = double(
      id:                 1337,
      title:              'Priority - Simple',
      key:                'priority_simple',
      type:               'text',
      removable:          true,
      active:             true,
      position:           1,
      required_in_portal: true,
      visible_in_portal:  true,
      required:           true,
      description:        'Example field',
    )

    expect(ObjectManager::Attribute).to receive(:migration_execute).and_return(true)

    expect do
      described_class.new(zendesk_object)
    end.not_to raise_error

    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name:   zendesk_object.key,
    )
  end
end

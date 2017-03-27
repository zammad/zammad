require 'rails_helper'

RSpec.describe Import::Zendesk::ObjectAttribute do

  it 'throws an exception if no init_callback is implemented' do

    attribute = double(
      title:              'Example attribute',
      description:        'Example attribute description',
      removable:          false,
      active:             true,
      position:           12,
      visible_in_portal:  true,
      required_in_portal: true,
      required:           true,
      type:               'input',
    )

    expect { described_class.new('Ticket', 'example_field', attribute) }.to raise_error(RuntimeError)
  end
end

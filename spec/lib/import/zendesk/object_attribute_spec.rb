require 'rails_helper'

RSpec.describe Import::Zendesk::ObjectAttribute do

  it 'extends ObjectManager Attribute exception text' do

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

    error_text = 'some error'
    expect(ObjectManager::Attribute).to receive(:add).and_raise(RuntimeError, error_text)

    exception = nil
    begin
      described_class.new('Ticket', 'example_field', attribute)
    rescue => e
      exception = e
    end

    expect(exception).not_to be nil
    expect(exception).to be_a(RuntimeError)
    expect(exception.message).to include(error_text)
    expect(exception.message).not_to eq(error_text)
  end
end

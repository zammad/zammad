# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

def dynamic_field_from_json(file, zammad_structure)
  expect(ObjectManager::Attribute).to receive(:add).with(zammad_structure)
  expect(ObjectManager::Attribute).to receive(:migration_execute)
  described_class.new(load_dynamic_field_json(file))
end

def load_dynamic_field_json(file)
  json_fixture("import/otrs/dynamic_field/#{file}")
end

RSpec.shared_examples 'Import::OTRS::DynamicField' do
  it 'responds to convert_name' do
    expect(described_class).to respond_to('convert_name')
  end
end

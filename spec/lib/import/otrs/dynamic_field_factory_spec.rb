# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/dynamic_field_examples'

RSpec.describe Import::OTRS::DynamicFieldFactory do
  let(:object_structure)  { [load_dynamic_field_json('text/default')] }
  let(:start_import_test) { described_class.import(object_structure) }

  it 'skips fields that have unsupported types' do
    described_class.import([load_dynamic_field_json('unsupported/master_slave')])
    expect(described_class.skip_field?('MasterSlave')).to be true
  end

  it 'imports OTRS DynamicFields' do
    expect(Import::OTRS::DynamicField::Text).to receive(:new)
    start_import_test
  end
end

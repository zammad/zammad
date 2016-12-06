require 'rails_helper'
require 'import/factory_examples'
require 'import/otrs/dynamic_field_examples'

RSpec.describe Import::OTRS::DynamicFieldFactory do
  it_behaves_like 'Import::Factory'

  let(:start_import_test) { described_class.import(object_structure) }
  let(:object_structure) { [load_dynamic_field_json('text/default')] }

  it 'responds to skip_field?' do
    expect(described_class).to respond_to('skip_field?')
  end

  it 'imports OTRS DynamicFields' do
    expect(Import::OTRS::DynamicField::Text).to receive(:new)
    start_import_test
  end
end

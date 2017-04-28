require 'rails_helper'
require 'lib/import/otrs/dynamic_field_examples'

RSpec.describe Import::OTRS::DynamicField do
  it_behaves_like 'Import::OTRS::DynamicField'

  let(:start_import_test) { described_class.new(object_structure) }
  let(:object_structure) { load_dynamic_field_json('text/default') }

  it 'requires an implementation of init_callback' do
    expect(ObjectManager::Attribute).to receive(:get).and_return(false)
    expect {
      start_import_test
    }.to raise_error(RuntimeError)
  end
end

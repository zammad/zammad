# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/dynamic_field_examples'

RSpec.describe Import::OTRS::DynamicField do
  let(:object_structure) { load_dynamic_field_json('text/default') }
  let(:start_import_test) { described_class.new(object_structure) }

  it_behaves_like 'Import::OTRS::DynamicField'

  it 'requires an implementation of init_callback' do
    allow(ObjectManager::Attribute).to receive(:get).and_return(false)
    expect do
      start_import_test
    end.to raise_error(RuntimeError)
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/import_factory_examples'

RSpec.describe Import::OTRS::SysConfigFactory do
  it_behaves_like 'Import factory'

  it 'stores default postmaster values' do

    value = 'new'

    settings = [
      {
        'Key'   => 'PostmasterDefaultState',
        'Value' => value
      }
    ]

    described_class.import(settings)

    expect(described_class.postmaster_default_lookup(:state_default_create)).to eq(value)
  end
end

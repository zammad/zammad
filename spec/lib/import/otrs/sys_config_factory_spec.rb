# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::SysConfigFactory do

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

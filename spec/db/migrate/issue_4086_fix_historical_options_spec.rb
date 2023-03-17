# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4086FixHistoricalOptions, type: :db_migration do
  let(:expected) do
    {
      'Sonstiges' => 'Sonstiges',
      'Hardware'  => 'Hardware',
      'Software'  => 'Software',
    }
  end

  let(:attribute) do
    attribute = create(:object_manager_attribute_select)
    attribute.data_option[:historical_options] = [
      { 'name' => 'Sonstiges', 'value' => 'Sonstiges' },
      { 'name' => 'Hardware', 'value' => 'Hardware' },
      { 'name' => 'Software', 'value' => 'Software' }
    ]
    attribute.save
    attribute
  end

  before do
    attribute
  end

  it 'does fix the broken historical_options' do
    migrate
    expect(attribute.reload.data_option[:historical_options]).to eq(expected)
  end
end

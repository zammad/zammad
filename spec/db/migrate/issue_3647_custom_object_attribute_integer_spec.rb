# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3647CustomObjectAttributeInteger, type: :db_migration do
  let(:integer_valid) { create(:object_manager_attribute_integer) }
  let(:integer_max_over_max) do
    object = build(:object_manager_attribute_integer, data_option: { default: 0, min: 0, max: 9_999_999_999 })
    object.save(validate: false)
    object
  end
  let(:integer_min_over_max) do
    object = build(:object_manager_attribute_integer, data_option: { default: 0, min: 9_999_999_999, max: 99_999_999_999 })
    object.save(validate: false)
    object
  end

  it 'leaves valid integer intact' do
    expect { migrate }
      .not_to change { integer_valid.data_option[:max] }
  end

  it 'lowers max if it is too big' do
    expect { migrate }
      .to change { integer_max_over_max.reload.data_option[:max] }
      .to 2_147_483_647
  end

  it 'lowers min if it is too big' do
    expect { migrate }
      .to change { integer_min_over_max.reload.data_option[:min] }
      .to 2_147_483_647
  end
end

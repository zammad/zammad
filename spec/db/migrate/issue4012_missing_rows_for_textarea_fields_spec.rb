# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4012MissingRowsForTextareaFields, type: :db_migration do
  let(:textarea_with_rows) do
    create(:object_manager_attribute_textarea, data_option: { default: 'dummy text', rows: 10, maxlength: 500 })
  end
  let(:textarea_without_rows) do
    object = build(:object_manager_attribute_textarea, data_option: { default: 'dummy text', rows: nil })
    object.save(validate: false)
    object
  end

  it 'does not change a valid textarea field' do
    expect { migrate }
      .not_to change { textarea_with_rows.data_option[:rows] }
  end

  it 'does change an invalid textarea field and inserts rows information' do
    expect { migrate }
      .to change { textarea_without_rows.reload.data_option[:rows] }
      .to 4
  end
end

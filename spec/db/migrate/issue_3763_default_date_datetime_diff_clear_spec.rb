# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3763DefaultDateDatetimeDiffClear, current_user_id: 1, type: :db_migration do
  shared_examples 'clears diff' do |type:|
    it "clears #{type} diffs" do
      object = create(type)

      migrate

      object.reload

      expect(object.data_option).to include(diff: nil, future: true)
    end
  end

  include_examples 'clears diff', type: 'date'
  include_examples 'clears diff', type: 'datetime'

  def create(type)
    ObjectManager::Attribute.add(
      object:      'Ticket',
      name:        'test_date',
      display:     __('Test Date'),
      data_type:   type,
      data_option: {
        future: true,
        past:   true,
        diff:   123,
      },
    )
  end
end

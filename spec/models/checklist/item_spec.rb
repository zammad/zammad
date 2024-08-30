# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Checklist::Item, :aggregate_failures, type: :model do
  describe 'history entries for checked' do
    let(:checklist) do
      create(:checklist, item_count: 1)
    end

    it 'creates history entries for checked' do
      checklist.items.first.update!(checked: true)

      history_type_id = History::Type.find_by(name: 'checklist_item_checked').id

      expect(History.last).to have_attributes(
        history_type_id: history_type_id,
        value_from:      checklist.items.first.text,
        value_to:        'true',
      )

      checklist.items.first.update!(checked: false)

      expect(History.last).to have_attributes(
        history_type_id: history_type_id,
        value_from:      checklist.items.first.text,
        value_to:        'false',
      )
    end
  end
end

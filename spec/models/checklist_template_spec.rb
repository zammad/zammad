# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ChecklistTemplate, :aggregate_failures, type: :model do
  describe 'validations' do
    context 'when limits are reached' do
      it 'does not allow more than 100 items' do
        checklist = create(:checklist_template, item_count: 100)
        expect { checklist.items.create!(text: 'new', created_by_id: 1, updated_by_id: 1) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Checklist Template items are limited to 100 items per checklist.')
      end
    end
  end
end

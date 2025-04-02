# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ChecklistTemplate, :aggregate_failures, current_user_id: 1, type: :model do
  describe '#replace_items!' do
    let(:template) { create(:checklist_template, item_count: 0) }

    it 'adds given items' do
      template.replace_items! %w[item1 item2]

      expect(template.sorted_items).to contain_exactly(
        have_attributes(text: 'item1'),
        have_attributes(text: 'item2')
      )
    end

    it 'ensures a limit of 100 items' do
      huge_list = Array.new(101, 'item')

      expect { template.replace_items!(huge_list) }
        .to raise_error(
          Exceptions::UnprocessableEntity,
          'Checklist Template items are limited to 100 items per checklist.'
        )
    end

    context 'when pre-existing items exist' do
      before do
        template.replace_items! %w[initial]
      end

      it 'drops pre-existing items' do
        template.replace_items! %w[item1 item2]

        expect(template.sorted_items).to contain_exactly(
          have_attributes(text: 'item1'),
          have_attributes(text: 'item2')
        )
      end
    end
  end
end

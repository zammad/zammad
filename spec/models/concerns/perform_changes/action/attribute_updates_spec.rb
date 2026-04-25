# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PerformChanges::Action::AttributeUpdates, type: :model do
  subject(:action) { described_class.new(record, execution_data, perform_changes_data) }

  let(:ticket)      { create(:ticket) }
  let(:record)      { ticket }
  let(:performable) { instance_double(Trigger, perform: {}, try: nil) }

  let(:perform_changes_data) do
    {
      performable:,
      origin:       'trigger',
      context_data:,
      user_id:      nil,
    }
  end

  describe '#execute' do
    context 'when skip_blank_attribute_values is set in context_data' do
      let(:context_data) { { skip_blank_attribute_values: true } }

      context 'when the attribute value is blank' do
        let(:execution_data) { { 'title' => { 'value' => '' } } }

        it 'does not update the attribute' do
          expect { action.execute }.not_to change { ticket.reload.title }
        end
      end

      context 'when the attribute value is present' do
        let(:execution_data) { { 'title' => { 'value' => 'New Title' } } }

        it 'updates the attribute' do
          action.execute
          expect(ticket.title).to eq('New Title')
        end
      end
    end

    context 'when skip_blank_attribute_values is not set' do
      let(:context_data) { {} }

      context 'when the attribute value is blank' do
        let(:execution_data) { { 'title' => { 'value' => '' } } }

        it 'updates the attribute to blank' do
          action.execute
          expect(ticket.title).to eq('')
        end
      end
    end
  end
end

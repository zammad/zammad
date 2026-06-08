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

    context 'when tags are provided' do
      # `tag_add` writes to ticket history via a polymorphic `sourceable` association,
      #   which requires a real ActiveRecord instance (an `instance_double` raises
      #   `NoMethodError: undefined method 'has_query_constraints?'`).
      let(:performable)  { create(:trigger) }
      let(:context_data) { {} }

      context 'when tags are provided as comma-separated string' do
        let(:execution_data) do
          {
            'tags' => {
              'operator' => 'add',
              'value'    => 'alpha, beta,alpha , foo, bar, bar',
            },
          }
        end

        it 'adds normalized unique tags' do
          action.execute

          expect(ticket.reload.tag_list).to contain_exactly('alpha', 'beta', 'foo', 'bar')
        end
      end

      context 'when tags are provided as array' do
        let(:execution_data) do
          {
            'tags' => {
              'operator' => 'add',
              'value'    => ['alpha', ' beta ', '', nil, 'alpha', 'foo', 'blub'],
            },
          }
        end

        it 'adds normalized unique tags' do
          action.execute

          expect(ticket.reload.tag_list).to contain_exactly('alpha', 'beta', 'foo', 'blub')
        end
      end

      context 'when operator is replace' do
        before { ticket.tag_add('existing', 1) }

        let(:execution_data) do
          {
            'tags' => {
              'operator' => 'replace',
              'value'    => %w[new-tag other],
            },
          }
        end

        it 'replaces all existing tags with the new ones' do
          action.execute

          expect(ticket.reload.tag_list).to contain_exactly('new-tag', 'other')
        end
      end

      context 'when operator is remove' do
        before do
          ticket.tag_add('alpha', 1)
          ticket.tag_add('beta', 1)
        end

        let(:execution_data) do
          {
            'tags' => {
              'operator' => 'remove',
              'value'    => ['alpha'],
            },
          }
        end

        it 'removes only the specified tag' do
          action.execute

          expect(ticket.reload.tag_list).to contain_exactly('beta')
        end
      end
    end
  end
end

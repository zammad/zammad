# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SqlHelper do
  describe '.quote_array_literal' do
    it 'wraps a simple value in single quotes' do
      expect(described_class.quote_array_literal('foo')).to eq("'foo'")
    end

    it 'doubles embedded single quotes' do
      expect(described_class.quote_array_literal("foo's")).to eq("'foo''s'")
    end

    it 'splits on ? so the fragment does not contain a raw ? placeholder (#6089)' do
      # A literal ? inside the quoted value would otherwise be counted as an
      # unfilled bind placeholder by ActiveRecord#build_bound_sql_literal and
      # raise ActiveRecord::PreparedStatementInvalid.
      result = described_class.quote_array_literal('trip?')
      expect(result).not_to include('?')
      expect(result).to eq("'trip' || chr(63) || ''")
    end

    it 'handles multiple ? in the same value' do
      result = described_class.quote_array_literal('a?b?c')
      expect(result).not_to include('?')
      expect(result).to eq("'a' || chr(63) || 'b' || chr(63) || 'c'")
    end
  end

  describe '#array_contains_one' do
    subject(:helper) { described_class.new(object: Ticket) }

    it 'inlines values that contain ? without leaking a raw ? into the SQL (#6089)' do
      sql = helper.array_contains_one('title', ['Why was I charged?'])
      expect(sql).not_to include('?')
      expect(sql).to include("'Why was I charged' || chr(63) || ''")
    end
  end

  describe '#array_contains_all' do
    subject(:helper) { described_class.new(object: Ticket) }

    it 'inlines values that contain ? without leaking a raw ? into the SQL (#6089)' do
      sql = helper.array_contains_all('title', ['trip?'])
      expect(sql).not_to include('?')
      expect(sql).to include("'trip' || chr(63) || ''")
    end
  end

  context 'when used through Ticket.selectors with a multi_tree_select value containing ?' do
    let(:attribute) do
      create(:object_manager_attribute_tree_select,
             object_name: 'Ticket',
             data_option: {
               options:             [
                 { name: 'Why was I charged?', value: 'Why was I charged?',
                   children: [{ name: 'Explained', value: 'Why was I charged?::Explained' }] },
               ],
               historical_options:  {
                 'Why was I charged?'            => 'Why was I charged?',
                 'Why was I charged?::Explained' => 'Explained',
               },
               default:             '',
               null:                true,
               translate:           false,
               relation:            '',
               multiple:            true,
               type:                'tree_select',
               nulloption:          true,
               options_raw:         '',
               rejectNonExistentValues: false,
             },
             screens: {
               'create_middle' => { 'ticket.agent' => { shown: true } },
               'edit'          => { 'ticket.agent' => { shown: true } },
             })
    end

    before do
      attribute
      ObjectManager::Attribute.migration_execute
    end

    it 'does not raise PreparedStatementInvalid (regression for #6089)' do
      condition = {
        operator:   'AND',
        conditions: [
          { name: "ticket.#{attribute.name}", operator: 'contains one',
            value: ['Why was I charged?::Explained'] },
        ],
      }

      expect { Ticket.selectors(condition, current_user: User.find(1), access: 'ignore') }.not_to raise_error
    end
  end
end

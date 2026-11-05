# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Selector::Base do
  let(:group_condition)    { { name: 'ticket.group_id', operator: 'is', value: [1] } }
  let(:priority_condition) { { name: 'ticket.priority_id', operator: 'is', value: [2] } }
  let(:simple_selector)    { { 'ticket.group_id' => { 'operator' => 'is', 'value' => [1] } } }
  let(:expert_selector) do
    {
      'operator'   => 'AND',
      'conditions' => [
        { 'name' => 'ticket.priority_id', 'operator' => 'is', 'value' => [2] },
        {
          'operator'   => 'AND',
          'conditions' => [
            { 'name' => 'ticket.group_id', 'operator' => 'is', 'value' => [1] },
          ],
        },
      ],
    }
  end

  describe '.and' do
    it 'combines simple and expert mode selectors as AND clause' do
      expect(described_class.and(simple_selector, expert_selector)).to eq(
        operator:   'AND',
        conditions: [
          { operator: 'AND', conditions: [group_condition] },
          { operator: 'AND', conditions: [priority_condition, { operator: 'AND', conditions: [group_condition] }] },
        ],
      )
    end
  end

  describe '.condition' do
    it 'finds a condition of a simple selector' do
      expect(described_class.condition(simple_selector, 'ticket.group_id')).to eq(group_condition)
    end

    it 'finds a condition in a nested AND block' do
      expect(described_class.condition(expert_selector, 'ticket.group_id')).to eq(group_condition)
    end

    it 'returns nil if the condition is missing' do
      expect(described_class.condition(expert_selector, 'ticket.owner_id')).to be_nil
    end

    it 'ignores conditions inside an OR block' do
      selector = { 'operator' => 'OR', 'conditions' => [group_condition, priority_condition] }

      expect(described_class.condition(selector, 'ticket.group_id')).to be_nil
    end

    it 'ignores conditions inside a NOT block' do
      selector = { 'operator' => 'AND', 'conditions' => [{ 'operator' => 'NOT', 'conditions' => [group_condition] }] }

      expect(described_class.condition(selector, 'ticket.group_id')).to be_nil
    end
  end

  describe '.without' do
    it 'removes a condition from a simple selector' do
      expect(described_class.without(simple_selector, 'ticket.group_id')).to eq(operator: 'AND', conditions: [])
    end

    it 'removes a condition from a nested AND block and keeps the rest' do
      expect(described_class.without(expert_selector, 'ticket.group_id')).to eq(
        operator:   'AND',
        conditions: [priority_condition, { operator: 'AND', conditions: [] }],
      )
    end

    it 'keeps conditions inside an OR block' do
      selector = { 'operator' => 'AND', 'conditions' => [{ 'operator' => 'OR', 'conditions' => [group_condition, priority_condition] }] }

      expect(described_class.without(selector, 'ticket.group_id')).to eq(
        operator:   'AND',
        conditions: [{ operator: 'OR', conditions: [group_condition, priority_condition] }],
      )
    end
  end
end

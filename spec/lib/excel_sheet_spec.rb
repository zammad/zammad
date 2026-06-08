# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExcelSheet do
  let(:document) { described_class.new(title: 'some title', header: [], records: [], timezone: 'Europe/Berlin', locale: 'de-de') }

  describe '.timestamp_in_localtime' do
    it 'does convert UTC timestamp to local system based timestamp' do
      expect(document.timestamp_in_localtime(Time.parse('2019-08-08T01:00:05Z').in_time_zone)).to eq('2019-08-08 03:00:05')
    end

  end

  describe 'Multiselect does not show values properly in reports #4186', db_strategy: :reset do
    let(:ticket) { create(:ticket, '4186_select': 'key_1', '4186_tree_select': 'Incident::Hardware', '4186_multiselect': %w[key_1 key_2], '4186_multi_tree_select': ['Incident', 'Incident::Hardware']) }

    before do
      create(:object_manager_attribute_select, name: '4186_select')
      create(:object_manager_attribute_tree_select, name: '4186_tree_select')
      create(:object_manager_attribute_multiselect, name: '4186_multiselect')
      create(:object_manager_attribute_multi_tree_select, name: '4186_multi_tree_select')
      ObjectManager::Attribute.migration_execute

      ticket
    end

    it 'does show select values formatted' do
      expect(document.value_lookup(ticket, '4186_select', ObjectManager::Attribute.find_by(name: '4186_select'), nil)).to eq('value_1')
    end

    it 'does show tree select values formatted' do
      expect(document.value_lookup(ticket, '4186_tree_select', ObjectManager::Attribute.find_by(name: '4186_tree_select'), nil)).to eq('Incident::Hardware')
    end

    it 'does show multiselect values formatted' do
      expect(document.value_lookup(ticket, '4186_multiselect', ObjectManager::Attribute.find_by(name: '4186_multiselect'), nil)).to eq('value_1,value_2')
    end

    it 'does show multi tree select values formatted' do
      expect(document.value_lookup(ticket, '4186_multi_tree_select', ObjectManager::Attribute.find_by(name: '4186_multi_tree_select'), nil)).to eq('Incident,Incident::Hardware')
    end
  end

  describe 'Tags are not displayed in the excel sheet of the report #5904' do
    let(:ticket) { create(:ticket) }
    let(:tag1)   { create(:tag, o: ticket, tag: 'tag1') }
    let(:tag2)   { create(:tag, o: ticket, tag: 'tag2') }
    let(:tag3)   { create(:tag, o: ticket, tag: 'tag3') }

    before do
      tag1 && tag2 && tag3
    end

    it 'does show tags value' do
      expect(document.value_lookup(ticket, 'tag_list', ObjectManager::Attribute.find_by(name: 'tags'), nil)).to eq('tag1,tag2,tag3')
    end
  end
end

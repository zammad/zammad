# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExternalSync do

  describe '#changed?' do

    it 'keeps ActiveRecord instance unchanged on local but no remote changes' do
      object           = create(:group)
      previous_changes = { name: 'Changed' }
      current_changes  = previous_changes.dup

      result = described_class.changed?(
        object:           object,
        previous_changes: previous_changes,
        current_changes:  current_changes,
      )

      expect(result).to                      be false
      expect(object.has_changes_to_save?).to be false
    end

    it 'keeps ActiveRecord instance unchanged on local and remote changes' do
      object           = create(:group)
      previous_changes = { name: 'Initial' }
      current_changes  = { name: 'Changed' }

      result = described_class.changed?(
        object:           object,
        previous_changes: previous_changes,
        current_changes:  current_changes,
      )

      expect(result).to                      be false
      expect(object.has_changes_to_save?).to be false
    end

    it 'changes ActiveRecord instance attribute(s) for remote changes' do
      object           = create(:group)
      previous_changes = { name: object.name }
      current_changes  = { name: 'Changed' }

      result = described_class.changed?(
        object:           object,
        previous_changes: previous_changes,
        current_changes:  current_changes,
      )

      expect(result).to                      be true
      expect(object.has_changes_to_save?).to be true
    end

    it 'prevents ActiveRecord method calls' do

      object           = create(:group)
      previous_changes = { name: object.name }
      current_changes  = { destroy: 'Changed' }

      result = described_class.changed?(
        object:           object,
        previous_changes: previous_changes,
        current_changes:  current_changes,
      )

      expect(result).to                      be false
      expect(object.has_changes_to_save?).to be false
      expect(object.destroyed?).to           be false
    end

  end

  describe '#map' do
    it 'maps to symbol keys' do
      mapping = {
        'key' => 'key'
      }

      source = {
        'key' => 'value'
      }

      result = {
        key: 'value'
      }

      expect(described_class.map(mapping: mapping, source: source)).to eq(result)
    end

    it 'resolves deep structures' do
      mapping = {
        'sub.structure.key' => 'key',
      }

      source = {
        'sub' => {
          'structure' => {
            'key' => 'value'
          }
        }
      }

      result = {
        key: 'value'
      }

      expect(described_class.map(mapping: mapping, source: source)).to eq(result)

      # check if sub structure is untouched
      expect(source['sub'].key?('structure')).to be true
    end

    it 'skips irrelevant keys' do
      mapping = {
        'key' => 'key'
      }

      source = {
        'key'     => 'value',
        'skipped' => 'skipped'
      }

      result = {
        key: 'value'
      }

      expect(described_class.map(mapping: mapping, source: source)).to eq(result)
    end

    it 'can handle object instances' do

      mapping = {
        'name' => 'key'
      }

      source = double(name: 'value')

      result = {
        key: 'value'
      }

      expect(described_class.map(mapping: mapping, source: source)).to eq(result)
    end

    it 'can handle ActiveRecord instances' do

      mapping = {
        'name' => 'key'
      }

      source = create(:group, name: 'value')

      result = {
        key: 'value'
      }

      expect(described_class.map(mapping: mapping, source: source)).to eq(result)
    end

    it 'prevents ActiveRecord method calls' do

      mapping = {
        'name'    => 'key',
        'destroy' => 'evil'
      }

      source = create(:group, name: 'value')

      result = {
        key: 'value'
      }

      expect(described_class.map(mapping: mapping, source: source)).to eq(result)
      expect(source.destroyed?).to be false
    end
  end

  describe '.migrate' do

    let(:model) { 'Ticket' }
    let(:factory_name) { model.downcase.to_sym }
    let(:source) { create(factory_name) }
    let(:target) { create(factory_name) }
    let(:entries) do
      create_list(:external_sync, 2,
                  object: model,
                  o_id:   source.id,)
    end

    it 'migrates entries' do
      expect do
        described_class.migrate('Ticket', source.id, target.id)
      end.to change {
        entries.each(&:reload).map(&:o_id).uniq
      }.from([source.id]).to([target.id])
    end
  end
end

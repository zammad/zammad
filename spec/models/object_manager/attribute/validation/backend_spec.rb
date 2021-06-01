# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManager::Attribute::Validation::Backend do

  describe 'backend interface' do

    subject do
      described_class.new(
        record:    record,
        attribute: attribute
      )
    end

    let(:record) { build(:user) }
    let(:attribute) { ::ObjectManager::Attribute.find_by(name: 'firstname') }

    it 'has attr_accessor for record' do
      expect(subject.record).to eq(record)
    end

    it 'has attr_accessor for attribute' do
      expect(subject.attribute).to eq(attribute)
    end

    it 'has attr_accessor for value' do
      expect(subject.value).to eq(record[attribute.name])
    end

    it 'has attr_accessor for previous_value' do
      record.save!
      previous_value         = record[attribute.name]
      record[attribute.name] = 'changed'
      expect(subject.previous_value).to eq(previous_value)
    end

    describe '.invalid_because_attribute' do

      before do
        subject.invalid_because_attribute('has value that is ... .')
      end

      it 'adds Rails validation error' do
        expect(record.errors.count).to be(1)
      end

      it 'uses ObjectManager::Attribute#name as ActiveModel::Errors identifier' do
        expect(record.errors.to_h).to have_key(attribute.name.to_sym)
      end
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Validations::ObjectManager::AttributeValidator::Backend, :aggregate_failures do

  describe 'backend interface' do

    subject(:backend) do
      described_class.new(
        record:    record,
        attribute: attribute
      )
    end

    let(:record)    { build(:user) }
    let(:attribute) { ObjectManager::Attribute.find_by(name: 'firstname') }

    it 'has attr_accessor for record' do
      expect(backend.record).to eq(record)
    end

    it 'has attr_accessor for attribute' do
      expect(backend.attribute).to eq(attribute)
    end

    it 'has attr_accessor for value' do
      expect(backend.value).to eq(record[attribute.name])
    end

    it 'has attr_accessor for previous_value' do
      record.save!
      previous_value         = record[attribute.name]
      record[attribute.name] = 'changed'
      expect(backend.previous_value).to eq(previous_value)
    end

    describe '.invalid_because_attribute' do

      before do
        backend.invalid_because_attribute(message, **options)
      end

      shared_examples 'basic error handling' do
        it 'adds Rails validation error' do
          expect(record.errors.count).to be(1)
          expect(record.errors.to_hash).to have_key(attribute.name.to_sym)
        end
      end

      context 'with plain message without parameter interpolation' do
        let(:message) { 'has value that is ...' }
        let(:options) { {} }

        include_examples 'basic error handling'

        context 'when translating the error message' do
          let(:custom_translations) { { 'has value that is ...' => 'hat einen Wert von ...', 'This field %s' => 'Dieses Feld %{message}' } }

          it 'produces a translated error message' do
            allow(Translation).to receive(:translate) { |_locale, string| custom_translations[string] || string }
            expect(record.errors.first.message).to eq('has value that is ...')
            expect(record.errors.first.localized_full_message(no_field_name: true, locale: 'de-de')).to eq('Dieses Feld hat einen Wert von ...')
          end
        end
      end

      context 'with message including parameter interpolation' do
        let(:message) { 'has value that is other than %{expected}' }
        let(:options) { { expected: 'my_value' } }

        include_examples 'basic error handling'

        context 'when translating the error message' do
          let(:custom_translations) { { 'has value that is other than %{expected}' => 'hat einen Wert abweichend von %{expected}', 'This field %s' => 'Dieses Feld %{message}' } }

          it 'produces a translated error message' do
            allow(Translation).to receive(:translate) { |_locale, string| custom_translations[string] || string }
            expect(record.errors.first.message).to eq('has value that is other than my_value')
            expect(record.errors.first.localized_full_message(no_field_name: true, locale: 'de-de')).to eq('Dieses Feld hat einen Wert abweichend von my_value')
          end
        end
      end
    end
  end
end

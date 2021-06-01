# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.shared_examples Import::Zendesk::ObjectAttribute::Base do
  let(:attribute) do
    double(
      title:                 'Example attribute',
      description:           'Example attribute description',
      removable:             false,
      active:                true,
      position:              12,
      visible_in_portal:     true,
      required_in_portal:    true,
      required:              true,
      type:                  'input',
      custom_field_options:  [],
      regexp_for_validation: '',
    )
  end

  describe 'exception handling' do
    let(:error_text) { Faker::Lorem.sentence }

    it 'extends ObjectManager Attribute exception message' do
      expect(ObjectManager::Attribute).to receive(:add).and_raise(RuntimeError, error_text)

      expect do
        described_class.new('Ticket', 'example_field', attribute)
      end.to raise_error(RuntimeError, %r{'example_field': #{error_text}$})
    end
  end

  describe 'argument handling' do
    it 'takes an ObjectLookup name as the first argument' do
      expect(ObjectManager::Attribute)
        .to receive(:add).with(hash_including(object: 'Ticket'))

      described_class.new('Ticket', 'example_field', attribute)
    end

    it 'accepts a constant ObjectLookup name' do
      expect(ObjectManager::Attribute)
        .to receive(:add).with(hash_including(object: 'Ticket'))

      described_class.new(Ticket, 'example_field', attribute)
    end
  end
end

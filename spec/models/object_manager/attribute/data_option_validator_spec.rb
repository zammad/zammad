# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManager::Attribute::DataOptionValidator, type: :model do
  let(:record)      { ObjectManager::Attribute.new(data_type: type, data_option: data_option) }
  let(:instance)    { described_class.new }
  let(:type)        { 'ibnput' }
  let(:data_option) { {} }

  describe '#validate', aggregate_failures: true do
    context 'when type is input' do
      let(:type) { 'input' }

      it 'runs expected validations' do
        allow(instance).to receive_messages(%i[type_check maxlength_check])
        instance.validate(record)
        expect(instance).to have_received(:type_check).with(record)
        expect(instance).to have_received(:maxlength_check).with(record)
      end
    end

    context 'when type is integer' do
      let(:type) { 'integer' }

      it 'runs expected validations' do
        allow(instance).to receive_messages([:min_max_check])
        instance.validate(record)
        expect(instance).to have_received(:min_max_check).with(record)
      end

    end

    context 'when type is boolean' do
      let(:type) { 'boolean' }

      it 'runs expected validations' do
        allow(instance).to receive_messages(%i[default_check presence_check])
        instance.validate(record)
        expect(instance).to have_received(:default_check).with(record)
        expect(instance).to have_received(:presence_check).with(record)
      end
    end

    context 'when type is datetime' do
      let(:type) { 'datetime' }

      it 'runs expected validations' do
        allow(instance).to receive_messages(%i[future_check past_check])
        instance.validate(record)
        expect(instance).to have_received(:future_check).with(record)
        expect(instance).to have_received(:past_check).with(record)
      end
    end

    %w[textarea richtext].each do |type|
      context "when type is #{type}" do
        let(:type) { type }

        it 'runs expected validations' do
          allow(instance).to receive_messages([:maxlength_check])
          instance.validate(record)
          expect(instance).to have_received(:maxlength_check).with(record)
        end
      end
    end

    %w[tree_select multi_tree_select multiselect select checkbox].each do |type|
      context "when type is #{type}" do
        let(:type) { type }

        it 'runs expected validations' do
          allow(instance).to receive_messages(%i[default_check relation_check])
          instance.validate(record)
          expect(instance).to have_received(:default_check).with(record)
          expect(instance).to have_received(:relation_check).with(record)
        end
      end
    end
  end

  describe '#maxlength_check' do
    before { instance.send(:maxlength_check, record) }

    context 'when maxlength is integer' do
      let(:data_option) { { maxlength: 123 } }

      it { expect(record.errors).to be_blank }
    end

    context 'when maxlength is string' do
      let(:data_option) { { maxlength: 'brbrbr' } }

      it { expect(record.errors.full_messages).to match_array('Max length must be an integer.') }
    end

    context 'when maxlength is missing' do
      it { expect(record.errors.full_messages).to match_array('Max length must be an integer.') }
    end
  end

  describe '#type_check' do
    before { instance.send(:type_check, record) }

    context 'when type is in the list' do
      let(:data_option) { { type: 'text' } }

      it { expect(record.errors).to be_blank }
    end

    context 'when type is not in the list' do
      let(:data_option) { { type: 'brbrbr' } }

      it { expect(record.errors.full_messages).to match_array('Input field must be text, password, tel, fax, email or url type.') }
    end

    context 'when type is missing' do
      it { expect(record.errors.full_messages).to match_array('Input field must be text, password, tel, fax, email or url type.') }
    end
  end

  describe '#default_check' do
    before { instance.send(:default_check, record) }

    context 'when default is truthy' do
      let(:data_option) { { default: 'text' } }

      it { expect(record.errors).to be_blank }
    end

    context 'when default is falsy' do
      let(:data_option) { { default: nil } }

      it { expect(record.errors).to be_blank }
    end

    context 'when default is not present' do
      it { expect(record.errors.full_messages).to match_array('Default value is required.') }
    end
  end

  describe '#relation_check' do
    before { instance.send(:relation_check, record) }

    context 'when options is present' do
      let(:data_option) { { options: { value: true } } }

      it { expect(record.errors).to be_blank }
    end

    context 'when options is empty' do
      let(:data_option) { { options: [] } }

      it { expect(record.errors).to be_blank }
    end

    context 'when relation is present' do
      let(:data_option) { { relation: 'sample' } }

      it { expect(record.errors).to be_blank }
    end

    context 'when relation is empty' do
      let(:data_option) { { relation: [] } }

      it { expect(record.errors).to be_blank }
    end

    context 'when neither optios nor relation present' do
      it { expect(record.errors.full_messages).to match_array('Options or relation is required.') }
    end
  end

  describe '#presence_check' do
    before { instance.send(:presence_check, record) }

    context 'when options is present' do
      let(:data_option) { { options: { value: true } } }

      it { expect(record.errors).to be_blank }
    end

    context 'when options is empty' do
      let(:data_option) { { options: [] } }

      it { expect(record.errors).to be_blank }
    end

    context 'when neither optios nor relation present' do
      it { expect(record.errors.full_messages).to match_array('Options are required.') }
    end
  end

  describe '#future_check' do
    before { instance.send(:future_check, record) }

    context 'when future is truthy' do
      let(:data_option) { { future: true } }

      it { expect(record.errors).to be_blank }
    end

    context 'when future is falsy' do
      let(:data_option) { { future: false } }

      it { expect(record.errors).to be_blank }
    end

    context 'when future is not present' do
      it { expect(record.errors.full_messages).to match_array('Allow future dates toggle value is required.') }
    end
  end

  describe '#past_check' do
    before { instance.send(:past_check, record) }

    context 'when past is truthy' do
      let(:data_option) { { past: true } }

      it { expect(record.errors).to be_blank }
    end

    context 'when past is falsy' do
      let(:data_option) { { past: false } }

      it { expect(record.errors).to be_blank }
    end

    context 'when past is not present' do
      it { expect(record.errors.full_messages).to match_array('Allow past dates toggle value is required.') }
    end
  end

  describe '#min_max_check' do
    before { instance.send(:min_max_check, record) }

    context 'when min & max are valid' do
      let(:data_option) { { min: -9, max: 9 } }

      it { expect(record.errors).to be_blank }
    end

    context 'when min is missing' do
      let(:data_option) { { min: nil } }

      it { expect(record.errors.full_messages).to include('Minimal value must be an integer') }
    end

    context 'when min is a string' do
      let(:data_option) { { min: '1' } }

      it { expect(record.errors.full_messages).to include('Minimal value must be an integer') }
    end

    context 'when min is too low' do
      let(:data_option) { { min: -2_147_483_648 } }

      it { expect(record.errors.full_messages).to include('Minimal value must be higher than -2147483648') }
    end

    context 'when min is too high' do
      let(:data_option) { { min: 2_147_483_648 } }

      it { expect(record.errors.full_messages).to include('Minimal value must be lower than 2147483648') }
    end

    context 'when max is missing' do
      let(:data_option) { { max: nil } }

      it { expect(record.errors.full_messages).to include('Minimal value must be an integer') }
    end

    context 'when max is a string' do
      let(:data_option) { { max: '1' } }

      it { expect(record.errors.full_messages).to include('Maximal value must be an integer') }
    end

    context 'when max is too low' do
      let(:data_option) { { max: -2_147_483_648 } }

      it { expect(record.errors.full_messages).to include('Maximal value must be higher than -2147483648') }
    end

    context 'when max is too high' do
      let(:data_option) { { max: 2_147_483_648 } }

      it { expect(record.errors.full_messages).to include('Maximal value must be lower than 2147483648') }
    end

    context 'when max is equal to min' do
      let(:data_option) { { min: 9, max: 9 } }

      it { expect(record.errors).to be_blank }
    end

    context 'when max is lower than min' do
      let(:data_option) { { min: 9, max: -9 } }

      it { expect(record.errors.full_messages).to include('Maximal value must be higher than or equal to minimal value') }
    end
  end
end

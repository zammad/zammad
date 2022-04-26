# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormSchema::Field::Telephone) do
  subject(:schema) { described_class.new(context: context, **base_attributes, **attributes).schema }

  let(:context) { Struct.new(:current_user, :current_user?) }

  context 'when generating schema information' do
    let(:type) { 'tel' }
    let(:base_attributes) do
      {
        name:  'my_field',
        label: 'Label',
        value: '+4912345678',
      }
    end
    let(:attributes) do
      {
        placeholder: '+4923456789',
        minlength:   20,
        maxlength:   40,
      }
    end

    it 'returns fields' do
      expect(schema).to eq(base_attributes.merge(type: type).merge({ props: attributes }))
    end
  end

end

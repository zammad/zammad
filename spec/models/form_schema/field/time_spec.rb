# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormSchema::Field::Time) do
  subject(:schema) { described_class.new(context: context, **base_attributes, **attributes).schema }

  let(:context) { Struct.new(:current_user, :current_user?) }

  context 'when generating schema information' do
    let(:type) { 'time' }
    let(:base_attributes) do
      {
        name:  'my_field',
        label: 'Label',
        value: '10:10',
      }
    end
    let(:attributes) do
      {
        min:  '10:10',
        max:  '20:20',
        step: '7',
      }
    end

    it 'returns fields' do
      expect(schema).to eq(base_attributes.merge(type: type).merge({ props: attributes }))
    end
  end
end

# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormSchema::Field::Select) do
  subject(:schema) { described_class.new(context: context, **base_attributes, **attributes).schema }

  let(:context) { Struct.new(:current_user, :current_user?) }

  context 'when generating schema information' do
    let(:type) { 'select' }
    let(:base_attributes) do
      {
        name:  'my_field',
        label: 'Label',
        value: 'initial content',
      }
    end
    let(:attributes) do
      {
        placeholder: 'nice placeholder',
        options:     [ { value: 'val1', label: 'label1' }, { value: 'val2', label: 'label2' } ],
        multiple:    true,
      }
    end

    it 'returns fields' do
      expect(schema).to eq(base_attributes.merge(type: type).merge({ props: attributes }))
    end
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TypeLookup, type: :model do
  describe '.by_name' do
    context 'with name matching an existing TypeLookup record' do
      subject(:type_lookup) { create(:type_lookup) }

      it 'returns its id' do
        expect(described_class.by_name(type_lookup.name))
          .to eq(type_lookup.id)
      end
    end

    context 'with name not matching any TypeLookup records' do
      let(:name) { 'FooBar' }

      it 'creates a new one with that name' do
        expect { described_class.by_name(name) }
          .to change(described_class, :count).by(1)

        expect(described_class.last.name).to eq(name)
      end

      it 'returns its id' do
        expect(described_class.by_name(name))
          .to eq(described_class.last.id)
      end

      context 'for names not in strict CamelCase' do
        let(:name) { 'Foo_Bar' }

        it 'does not modify the format' do
          described_class.by_name(name)

          expect(described_class.last.name).to eq(name)
        end
      end
    end
  end

  describe '.by_id' do
    context 'with number matching an existing TypeLookup#id' do
      subject(:type_lookup) { create(:type_lookup) }

      it 'returns its name' do
        expect(described_class.by_id(type_lookup.id))
          .to eq(type_lookup.name)
      end
    end
  end
end

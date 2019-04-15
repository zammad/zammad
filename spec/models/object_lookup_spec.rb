require 'rails_helper'

RSpec.describe ObjectLookup, type: :model do
  describe '.by_name' do
    context 'with name matching an existing ObjectLookup record' do
      subject(:object_lookup) { create(:object_lookup) }

      it 'returns its id' do
        expect(ObjectLookup.by_name(object_lookup.name))
          .to eq(object_lookup.id)
      end
    end

    context 'with name not matching any ObjectLookup records' do
      let(:name) { 'FooBar' }

      it 'creates a new one with that name' do
        expect { ObjectLookup.by_name(name) }
          .to change(ObjectLookup, :count).by(1)

        expect(ObjectLookup.last.name).to eq(name)
      end

      it 'returns its id' do
        expect(ObjectLookup.by_name(name))
          .to eq(ObjectLookup.last.id)
      end

      context 'for names not in strict CamelCase' do
        let(:name) { 'Foo_Bar' }

        it 'does not modify the format' do
          ObjectLookup.by_name(name)

          expect(ObjectLookup.last.name).to eq(name)
        end
      end
    end
  end

  describe '.by_id' do
    context 'with number matching an existing ObjectLookup#id' do
      subject(:object_lookup) { create(:object_lookup) }

      it 'returns its name' do
        expect(ObjectLookup.by_id(object_lookup.id))
          .to eq(object_lookup.name)
      end
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'ApplicationModel::HasCache' do
  describe '#cache_delete' do
    let(:instance) { create(described_class.name.underscore) }

    it 'clears cache after updating the object' do
      allow(instance).to receive(:cache_delete)

      instance.touch

      expect(instance).to have_received(:cache_delete)
    end

    it 'clears cache after deleting the object' do
      allow(instance).to receive(:cache_delete)

      instance.destroy

      expect(instance).to have_received(:cache_delete)
    end
  end
end

RSpec.shared_examples 'Association clears cache' do |association:, factory: nil|
  describe "#{association} association clears cache", aggregate_failures: true do
    let(:instance)     { create(described_class.name.underscore) }
    let(:other_object) { create(factory || association.to_s.singularize) }

    it 'after adding an object to collection' do
      allow(instance).to receive(:cache_delete)
      allow(other_object).to receive(:cache_delete)

      instance.send(association) << other_object

      expect(instance).to have_received(:cache_delete).at_least(:once)
      expect(other_object).to have_received(:cache_delete).at_least(:once)
    end

    it 'after removing an object from collection' do
      instance.send(association) << other_object

      allow(instance).to receive(:cache_delete)
      allow(other_object).to receive(:cache_delete)

      instance.send(association).delete(other_object)

      expect(instance).to have_received(:cache_delete).at_least(:once)
      expect(other_object).to have_received(:cache_delete).at_least(:once)
    end
  end
end

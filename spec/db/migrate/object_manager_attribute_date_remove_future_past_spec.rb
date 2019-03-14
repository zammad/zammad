require 'rails_helper'

RSpec.describe ObjectManagerAttributeDateRemoveFuturePast, type: :db_migration do
  context 'when Date ObjectManager::Attribute exists' do

    it 'removes future and past data_option' do
      subject = build(:object_manager_attribute_date)

      # add data_options manually because the factory doesn't contain them anymore
      subject.data_option = subject.data_option.merge(
        future: false,
        past:   false,
      )

      # mock interfaces to save time
      # otherwise we would have to reseed the database
      expect(ObjectManager::Attribute).to receive(:where).and_return([subject])
      expect(subject).to receive(:save!)

      migrate

      expect(subject.data_option).to_not include(:past, :future)
    end
  end
end

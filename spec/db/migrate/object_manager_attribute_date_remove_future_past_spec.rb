# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
      allow(ObjectManager::Attribute).to receive(:where).and_return([subject])
      allow(subject).to receive(:save!)

      migrate

      expect(subject.data_option).not_to include(:past, :future)
    end

    context 'when incomplete data_option is given' do

      it 'adds missing :diff option' do
        subject = build(:object_manager_attribute_date)

        # add data_options manually because the factory doesn't contain them anymore
        subject.data_option = subject.data_option.merge(
          future: false,
          past:   false,
        )

        # remove diff option as for some attributes
        # from older Zammad installations
        subject.data_option.delete(:diff)

        # mock interfaces to save time
        # otherwise we would have to reseed the database
        allow(ObjectManager::Attribute).to receive(:where).and_return([subject])
        # expect(subject).to receive(:save!)

        expect { migrate }.not_to raise_error
      end
    end
  end
end

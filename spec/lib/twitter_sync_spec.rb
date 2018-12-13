require 'rails_helper'

RSpec.describe TwitterSync do
  describe '.preferences_cleanup' do
    describe 'sanitizing Twitter preferences' do
      context 'when given as a bare hash' do
        it 'automatically adds empty hashes at :geo and :place' do
          expect(described_class.preferences_cleanup({}))
            .to eq({ geo: {}, place: {} })
        end

        it 'does not modify values at :mention_ids' do
          expect(described_class.preferences_cleanup({ mention_ids: [1_234_567_890] }))
            .to include({ mention_ids: [1_234_567_890] })
        end

        it 'converts geo: instance_of(Twitter::NullOjbect) to empty hash' do
          expect(described_class.preferences_cleanup({ geo: Twitter::NullObject.new }))
            .to include(geo: {})
        end

        it 'converts geo: instance_of(Twitter::Geo.new) to matching hash' do
          expect(described_class.preferences_cleanup({ geo: Twitter::Geo.new(coordinates: [1, 1]) }))
            .to include(geo: { coordinates: [1, 1] })
        end

        it 'converts place: instance_of(Twitter::NullOjbect) to empty hash' do
          expect(described_class.preferences_cleanup({ place: Twitter::NullObject.new }))
            .to include(place: {})
        end

        it 'converts place: instance_of(Twitter::Place.new) to matching hash' do
          place_data = { country: 'da', name: 'do', woeid: 1, id: 1 }

          expect(described_class.preferences_cleanup({ place: Twitter::Place.new(place_data) }))
            .to include(place: place_data)
        end
      end

      context 'when given nested in an article preferences hash' do
        it 'automatically adds empty hashes at :geo and :place' do
          expect(described_class.preferences_cleanup({ twitter: {} }))
            .to eq(twitter: { geo: {}, place: {} })
        end

        it 'does not modify values at :mention_ids' do
          expect(described_class.preferences_cleanup({ twitter: { mention_ids: [1_234_567_890] } }))
            .to include(twitter: hash_including(mention_ids: [1_234_567_890]))
        end

        it 'converts geo: instance_of(Twitter::NullOjbect) to empty hash' do
          expect(described_class.preferences_cleanup({ twitter: { geo: Twitter::NullObject.new } }))
            .to include(twitter: hash_including(geo: {}))
        end

        it 'converts geo: instance_of(Twitter::Geo.new) to matching hash' do
          expect(described_class.preferences_cleanup({ twitter: { geo: Twitter::Geo.new(coordinates: [1, 1]) } }))
            .to include(twitter: hash_including(geo: { coordinates: [1, 1] }))
        end

        it 'converts place: instance_of(Twitter::NullOjbect) to empty hash' do
          expect(described_class.preferences_cleanup({ twitter: { place: Twitter::NullObject.new } }))
            .to include(twitter: hash_including(place: {}))
        end

        it 'converts place: instance_of(Twitter::Place.new) to matching hash' do
          place_data = { country: 'da', name: 'do', woeid: 1, id: 1 }

          expect(described_class.preferences_cleanup({ twitter: { place: Twitter::Place.new(place_data) } }))
            .to include(twitter: hash_including(place: place_data))
        end
      end
    end
  end
end

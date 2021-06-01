# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TwitterSync do
  subject(:twitter_sync) { described_class.new(channel.options[:auth]) }

  let(:channel) { create(:twitter_channel) }

  describe '.preferences_cleanup' do
    shared_examples 'for normalizing input' do
      it 'is converted (from bare hash)' do
        expect(described_class.preferences_cleanup(raw_preferences)).to include(clean_preferences)
      end

      it 'is converted (from article.preferences hash)' do
        expect(described_class.preferences_cleanup(twitter: raw_preferences)).to match({ twitter: hash_including(clean_preferences) })
      end
    end

    describe ':geo key' do
      context 'when absent' do
        let(:raw_preferences) { {} }
        let(:clean_preferences) { { geo: {} } }

        include_examples 'for normalizing input'
      end

      context 'when instance_of(Twitter::NullOjbect)' do
        let(:raw_preferences) { { geo: Twitter::NullObject.new } }
        let(:clean_preferences) { { geo: {} } }

        include_examples 'for normalizing input'
      end

      context 'when instance_of(Twitter::Geo.new)' do
        let(:raw_preferences) { { geo: Twitter::Geo.new(coordinates: [1, 1]) } }
        let(:clean_preferences) { { geo: { coordinates: [1, 1] } } }

        include_examples 'for normalizing input'
      end
    end

    describe ':place key' do
      context 'when absent' do
        let(:raw_preferences) { {} }
        let(:clean_preferences) { { place: {} } }

        include_examples 'for normalizing input'
      end

      context 'when instance_of(Twitter::NullOjbect)' do
        let(:raw_preferences) { { place: Twitter::NullObject.new } }
        let(:clean_preferences) { { place: {} } }

        include_examples 'for normalizing input'
      end

      context 'when instance_of(Twitter::Place.new)' do
        let(:raw_preferences) { { place: Twitter::Place.new({ country: 'da', name: 'do', woeid: 1, id: 1 }) } }
        let(:clean_preferences) { { place: { country: 'da', name: 'do', woeid: 1, id: 1 } } }

        include_examples 'for normalizing input'
      end
    end

    describe ':mention_ids key' do
      let(:raw_preferences) { { mention_ids: [1_234_567_890] } }
      let(:clean_preferences) { { mention_ids: [1_234_567_890] } }

      include_examples 'for normalizing input'
    end
  end
end

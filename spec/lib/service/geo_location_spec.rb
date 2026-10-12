# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::GeoLocation do
  let(:address)   { 'Marienstrasse 13, 10117 Berlin' }
  let(:latitude)  { 52.5220514 }
  let(:longitude) { 13.3832091 }

  describe '#geocode' do
    subject(:geocode) { described_class.geocode(address) }

    before do
      allow(Service::GeoLocation::Osm).to receive(:geocode).and_return([latitude, longitude])
    end

    context 'with the configured backend' do
      before { Setting.set('geo_location_backend', 'Service::GeoLocation::Osm') }

      it 'returns the result of the backend', :aggregate_failures do
        expect(geocode).to eq([latitude, longitude])
        expect(Service::GeoLocation::Osm).to have_received(:geocode).with(address)
      end
    end

    context 'without a configured backend' do
      before { Setting.set('geo_location_backend', '') }

      it 'does not perform a lookup', :aggregate_failures do
        expect(geocode).to be_nil
        expect(Service::GeoLocation::Osm).not_to have_received(:geocode)
      end
    end
  end

  describe '#reverse_geocode' do
    subject(:reverse_geocode) { described_class.reverse_geocode(latitude, longitude) }

    let(:result) { '13, Marienstraße, Dorotheenstadt, Mitte, Berlin, 10117, Deutschland' }

    before do
      allow(Service::GeoLocation::Osm).to receive(:reverse_geocode).and_return(result)
    end

    context 'with the configured backend' do
      before { Setting.set('geo_location_backend', 'Service::GeoLocation::Osm') }

      it 'returns the result of the backend', :aggregate_failures do
        expect(reverse_geocode).to eq(result)
        expect(Service::GeoLocation::Osm).to have_received(:reverse_geocode).with(latitude, longitude)
      end
    end

    context 'without a configured backend' do
      before { Setting.set('geo_location_backend', '') }

      it 'does not perform a lookup', :aggregate_failures do
        expect(reverse_geocode).to be_nil
        expect(Service::GeoLocation::Osm).not_to have_received(:reverse_geocode)
      end
    end
  end
end

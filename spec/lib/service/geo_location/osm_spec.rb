# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::GeoLocation::Osm, :integration, use_vcr: true do
  before do
    # NB: Exclude possible geocoding matches, in order to always receive same coordinates for purpose of this test.
    #   https://nominatim.org/release-docs/develop/api/Search/#result-restriction
    stub_const('Service::GeoLocation::Osm::OSM_SEARCH_URL', "#{Service::GeoLocation::Osm::OSM_SEARCH_URL}&exclude_place_ids=158906443")
  end

  describe '#geocode' do
    subject(:geocode) { described_class.geocode(address) }

    context 'with a german address' do
      let(:address) { 'Marienstrasse 13, 10117 Berlin' }
      let(:result)  { [52.5220514, 13.3832091] }

      it { is_expected.to eq(result) }

      context 'without a separator between street, zipcode and city' do
        let(:address) { 'Marienstrasse 13 10117 Berlin' }

        it { is_expected.to eq(result) }
      end
    end

    context 'with a swiss address' do
      let(:address) { 'Martinsbruggstrasse 35, 9016 St. Gallen' }
      let(:result)  { [47.43664765, 9.409934047751209] }

      it { is_expected.to eq(result) }

      context 'without a separator between street, zipcode and city' do
        let(:address) { 'Martinsbruggstrasse 35 9016 St. Gallen' }

        it { is_expected.to eq(result) }
      end
    end
  end

  describe '#reverse_geocode' do
    subject(:reverse_geocode) { described_class.reverse_geocode(latitude, longitude) }

    context 'with german coordinates' do
      let(:latitude)  { 52.5220514 }
      let(:longitude) { 13.3832091 }
      let(:result)    { '13, Marienstraße, Dorotheenstadt, Mitte, Berlin, 10117, Deutschland' }

      it { is_expected.to eq(result) }
    end

    context 'with swiss coordinates' do
      let(:latitude)  { 47.43664765 }
      let(:longitude) { 9.409934047751209 }
      let(:result)    { '35, Martinsbruggstrasse, Neudorf, St. Gallen, Wahlkreis St. Gallen, St. Gallen, 9016, Schweiz/Suisse/Svizzera/Svizra' }

      it { is_expected.to eq(result) }
    end
  end
end

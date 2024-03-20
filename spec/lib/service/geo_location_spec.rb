# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::GeoLocation do
  describe '#geocode' do
    subject(:geocode) { described_class.geocode(address) }

    context 'when checking simple results' do
      let(:address)   { 'Marienstrasse 13, 10117 Berlin' }
      let(:latitude)  { 52.5220514 }
      let(:longitude) { 13.3832091 }
      let(:result)    { [latitude, longitude] }

      before do
        allow(Service::GeoLocation::Osm).to receive(:geocode).and_return(result)
      end

      it { is_expected.to eq(result) }

      context 'when address field in user preferences is filled' do
        let(:user) { create(:user, address: address) }

        it 'stores correct values for latitude + longitude' do
          expect(user.preferences).to include({ 'lat' => latitude, 'lng' => longitude })
        end
      end

      context 'when street, city and zip fields in user preferences are filled' do
        let(:address)       { 'Marienstrasse 13, 10117, Berlin' }
        let(:address_parts) { address.split(%r{\.?\s+}, 4) }
        let(:street)        { "#{address_parts.first} #{address_parts[1].chop}" }
        let(:zip)           { address_parts[2].chop }
        let(:city)          { address_parts.last }

        let(:user) { create(:user, street: street, zip: zip, city: city) }

        it 'stores correct values for latitude + longitude' do
          expect(user.preferences).to include({ 'lat' => latitude, 'lng' => longitude })
        end
      end
    end
  end

  describe '#reverse_geocode' do
    subject(:reverse_geocode) { described_class.reverse_geocode(latitude, longitude) }

    context 'when checking simple results' do
      let(:latitude)        { 52.5220514 }
      let(:longitude)       { 13.3832091 }
      let(:result)          { '13, Marienstraße, Dorotheenstadt, Mitte, Berlin, 10117, Deutschland' }

      before do
        allow(Service::GeoLocation::Osm).to receive(:reverse_geocode).and_return(result)
      end

      it { is_expected.to eq(result) }
    end
  end
end

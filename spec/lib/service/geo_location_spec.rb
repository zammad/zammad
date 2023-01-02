# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::GeoLocation, integration: true do
  describe '#geocode' do
    subject(:lookup_result) { described_class.geocode(address) }

    context 'when checking simple results' do
      let(:expected_result) { [ latitude, longitude ] }
      let(:request_url)     { "http://maps.googleapis.com/maps/api/geocode/json?address=#{CGI.escape(address)}&sensor=true" }
      let(:response_payload) do
        {
          'results' => [
            {
              'geometry' => {
                'location' => {
                  'lat' => latitude,
                  'lng' => longitude,
                },
              },
            },
          ],
        }
      end

      before do
        stub_request(:get, request_url).to_return(status: 200, body: response_payload.to_json, headers: {})
      end

      context 'with German addresses' do
        let(:address) { 'Marienstrasse 13, 10117 Berlin' }
        let(:latitude)  { 52.5219143 }
        let(:longitude) { 13.3832647 }

        it { is_expected.to eq(expected_result) }

        context 'without separator between street and zipcode + city' do
          let(:address) { 'Marienstrasse 13 10117 Berlin' }

          it { is_expected.to eq(expected_result) }
        end

        context 'when address field in user preferences is filled' do
          let(:user) { create(:user, address: address) }

          it 'stores correct values for latitude + longitude' do
            expect(user.preferences).to include({ 'lat' => latitude, 'lng' => longitude })
          end
        end

        context 'when street, city and zip fields in user preferences are filled' do
          let(:address) { 'Marienstrasse 13, 10117, Berlin' }
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

      context 'with Swiss addresses' do
        let(:address)   { 'Martinsbruggstrasse 35, 9016 St. Gallen' }
        let(:latitude)  { 47.4366557 }
        let(:longitude) { 9.4098904 }

        it { is_expected.to eq(expected_result) }

        context 'without separator between street and zipcode + city' do
          let(:address) { 'Martinsbruggstrasse 35 9016 St. Gallen' }

          it { is_expected.to eq(expected_result) }
        end
      end
    end
  end

  describe '#reverse_geocode' do
    subject(:lookup_result) { described_class.reverse_geocode(latitude, longitude) }

    context 'when checking simple results' do
      let(:expected_result) { address }
      let(:request_url)     { "http://maps.googleapis.com/maps/api/geocode/json?latlng=#{latitude},#{longitude}&sensor=true" }
      let(:response_payload) do
        {
          'results' => [
            {
              'address_components' => [
                'long_name' => address,
              ],
            },
          ],
        }
      end

      before do
        stub_request(:get, request_url).to_return(status: 200, body: response_payload.to_json, headers: {})
      end

      context 'with German addresses' do
        let(:address) { 'Marienstrasse 13, 10117 Berlin' }
        let(:latitude)  { 52.5219143 }
        let(:longitude) { 13.3832647 }

        it { is_expected.to eq(expected_result) }
      end

      context 'with Swiss addresses' do
        let(:address) { 'Martinsbruggstrasse 35, 9016 St. Gallen' }
        let(:latitude)  { 47.4366557 }
        let(:longitude) { 9.4098904 }

        it { is_expected.to eq(expected_result) }
      end
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::GeoIp, integration: true, retry: 5, retry_wait: 30.seconds do
  describe '#location' do
    describe 'testing some locations' do
      subject(:lookup_result) { described_class.location(ip_address) }

      context 'with no results for locations' do
        context 'with invalid ip address' do
          let(:ip_address) { '127.0.0.0.1' }

          it { is_expected.to be_blank }
        end

        context 'with ip address of localhost' do
          let(:ip_address) { '127.0.0.1' }

          it { is_expected.to be_blank }
        end
      end

      shared_examples 'contains correct data for location' do
        it { is_expected.to include(expected_result) }
      end

      context 'with correct results for locations' do
        context 'with Swiss ip address' do
          let(:ip_address) { '195.65.29.254' }
          let(:expected_result) do
            {
              'country_name'   => 'Switzerland',
              'country_code'   => 'CH',
              'continent_code' => 'EU',
              'latitude'       => be_a(Float),
              'longitude'      => be_a(Float),
            }
          end

          include_examples 'contains correct data for location'
        end

        context 'with German ip address (Chemnitz)' do
          let(:ip_address) { '134.109.140.74' }
          let(:expected_result) do
            {
              'country_name'   => 'Germany',
              'city_name'      => be_present,
              'country_code'   => 'DE',
              'continent_code' => 'EU',
              'latitude'       => be_a(Float),
              'longitude'      => be_a(Float),
            }
          end

          include_examples 'contains correct data for location'
        end

        context 'with German ip address (Halle)' do
          let(:ip_address) { '46.253.55.170' }
          let(:expected_result) do
            {
              'country_name'   => 'Germany',
              'city_name'      => be_present,
              'country_code'   => 'DE',
              'continent_code' => 'EU',
              'latitude'       => be_a(Float),
              'longitude'      => be_a(Float),
            }
          end

          include_examples 'contains correct data for location'
        end

        context 'with US ip address' do
          let(:ip_address) { '169.229.216.200' }
          let(:expected_result) do
            {
              'country_name'   => 'United States',
              'city_name'      => be_present,
              'country_code'   => 'US',
              'continent_code' => 'NA',
              'latitude'       => be_a(Float),
              'longitude'      => be_a(Float),
            }
          end

          include_examples 'contains correct data for location'
        end
      end
    end
  end
end

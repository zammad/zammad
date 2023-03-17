# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::GeoCalendar, integration: true do
  describe '#location' do
    describe 'testing some locations' do
      subject(:lookup_result) { described_class.location(ip_address) }

      shared_examples 'contains correct data for location' do
        it { is_expected.to include(expected_result) }
      end

      context 'with default/fallback values' do
        let(:expected_result) do
          {
            'name'     => 'My Calendar',
            'timezone' => 'America/Los_Angeles',
            'ical_url' => '',
          }
        end

        context 'with invalid ip address' do
          let(:ip_address) { '127.0.0.0.1' }

          include_examples 'contains correct data for location'
        end

        context 'with ip address of localhost' do
          let(:ip_address) { '127.0.0.1' }

          include_examples 'contains correct data for location'
        end
      end

      context 'with correct results for Swiss ip addresses' do
        let(:expected_result) do
          {
            'name'     => 'Switzerland',
            'timezone' => 'Europe/Zurich',
            'ical_url' => 'https://www.google.com/calendar/ical/de.ch%23holiday%40group.v.calendar.google.com/public/basic.ics',
          }
        end

        context 'with Swiss ip #1' do
          let(:ip_address) { '195.65.29.254' }

          include_examples 'contains correct data for location'
        end

        context 'with Swiss ip #2' do
          let(:ip_address) { '195.191.132.18' }

          include_examples 'contains correct data for location'
        end
      end

      context 'with correct results for German ip addresses' do
        let(:expected_result) do
          {
            'name'     => 'Germany',
            'timezone' => 'Europe/Berlin',
            'ical_url' => 'https://www.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics',
          }
        end

        context 'with German ip #1' do
          let(:ip_address) { '134.109.140.74' }

          include_examples 'contains correct data for location'
        end

        context 'with German ip #2' do
          let(:ip_address) { '46.253.55.170' }

          include_examples 'contains correct data for location'
        end
      end

      context 'with correct results for US ip addresses' do
        let(:expected_result) do
          {
            'name'     => name,
            'timezone' => timezone,
            'ical_url' => 'https://www.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics',
          }
        end

        context 'with US ip #1' do
          let(:ip_address) { '169.229.216.200' }
          let(:name)       { 'United States/California' }
          let(:timezone)   { 'America/Los_Angeles' }

          include_examples 'contains correct data for location'
        end

        context 'with US ip #2' do
          let(:ip_address) { '17.171.2.25' }
          let(:name)     { 'United States' }
          let(:timezone) { 'America/Chicago' }

          include_examples 'contains correct data for location'

          context 'with US ip #3' do
            let(:ip_address) { '184.168.47.225' }

            include_examples 'contains correct data for location'
          end
        end
      end

      context 'with correct result for Canadian ip address' do
        let(:expected_result) do
          {
            'name'     => 'Canada',
            'timezone' => 'America/Toronto',
            'ical_url' => 'https://www.google.com/calendar/ical/en.canadian%23holiday%40group.v.calendar.google.com/public/basic.ics',
          }
        end

        let(:ip_address) { '69.172.201.245' }

        include_examples 'contains correct data for location'
      end

      context 'with correct result for Mexican ip address' do
        let(:expected_result) do
          {
            'name'     => 'Mexico/Mexico City',
            'timezone' => 'America/Mexico_City',
            'ical_url' => 'https://www.google.com/calendar/ical/en.mexican%23holiday%40group.v.calendar.google.com/public/basic.ics',
          }
        end

        let(:ip_address) { '132.247.70.37' }

        include_examples 'contains correct data for location'
      end
    end
  end
end

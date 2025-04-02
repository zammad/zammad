# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe GeoLocationBackendOsm, type: :db_migration do
  let(:setting)       { Setting.find_by(name: 'geo_location_backend') }
  let(:current_value) { 'Service::GeoLocation::Gmaps' }

  def revert_setting
    setting.state_current = { 'value' => current_value }
    setting.state_initial = { 'value' => 'Service::GeoLocation::Gmaps' }
    setting.options['form'][0]['options'].delete('Service::GeoLocation::Osm')
    setting.options['form'][0]['options']['Service::GeoLocation::Gmaps'] = 'Google Maps'
    setting.save!
  end

  before do
    revert_setting
    migrate
  end

  it 'migrates the setting' do
    expect(setting.reload).to have_attributes(
      state_current: { 'value' => 'Service::GeoLocation::Osm' },
      state_initial: { 'value' => 'Service::GeoLocation::Osm' },
      options:       {
        'form' => [
          include('options' => include(
            'Service::GeoLocation::Osm' => 'OpenStreetMap (ODbL 1.0, http://osm.org/copyright)',
          ))
        ]
      }
    ).and have_attributes(options: { 'form' => [include('options' => not_include('Service::GeoLocation::Gmaps' => 'Google Maps'))] })
  end

  context 'with non-default value' do
    let(:current_value) { '' }

    it 'does not change setting value' do
      expect(setting.reload).to have_attributes(
        state_current: { 'value' => '' },
      )
    end
  end
end

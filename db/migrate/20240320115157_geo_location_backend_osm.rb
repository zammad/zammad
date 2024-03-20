# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class GeoLocationBackendOsm < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'geo_location_backend')&.tap do |setting|
      setting.state_current = { 'value' => 'Service::GeoLocation::Osm' } if setting.state_current['value'] == 'Service::GeoLocation::Gmaps'
      setting.state_initial = { 'value' => 'Service::GeoLocation::Osm' }
      setting.options['form'][0]['options'].delete('Service::GeoLocation::Gmaps')
      setting.options['form'][0]['options']['Service::GeoLocation::Osm'] = 'OpenStreetMap (ODbL 1.0, http://osm.org/copyright)'
      setting.save!
    end
  end
end

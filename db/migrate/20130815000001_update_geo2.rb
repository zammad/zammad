class UpdateGeo2 < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      :title       => 'Geo Location Backend',
      :name        => 'geo_location_backend',
      :area        => 'System::Geo',
      :description => 'Defines the backend for geo location lookups.',
      :options     => {
        :form => [
          {
            :display  => '',
            :null     => true,
            :name     => 'geo_location_backend',
            :tag      => 'select',
            :options  => {
              '' => '-',
              'GeoLocation::Gmaps' => 'Google Maps',
            },
          },
        ],
      },
      :state    => 'GeoLocation::Gmaps',
      :frontend => false
    )
    Setting.create_if_not_exists(
      :title       => 'Geo IP Backend',
      :name        => 'geo_ip_backend',
      :area        => 'System::Geo',
      :description => 'Defines the backend for geo ip lookups.',
      :options     => {
        :form => [
          {
            :display  => '',
            :null     => true,
            :name     => 'geo_ip_backend',
            :tag      => 'select',
            :options  => {
              '' => '-',
              'GeoIp::Freegeoip' => 'freegeoip.net',
            },
          },
        ],
      },
      :state    => 'GeoIp::Freegeoip',
      :frontend => false
    )
  end
  def down
  end
end


class UpdateGeoIpConfig < ActiveRecord::Migration
  def up
    Setting.create_or_update(
      title: 'Geo IP Backend',
      name: 'geo_ip_backend',
      area: 'System::Geo',
      description: 'Defines the backend for geo ip lookups.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'geo_ip_backend',
            tag: 'select',
            options: {
              '' => '-',
              'GeoIp::ZammadGeoIp' => 'Zammad GeoIP Service',
            },
          },
        ],
      },
      state: 'GeoIp::ZammadGeoIp',
      frontend: false
    )
  end

  def down
  end

end

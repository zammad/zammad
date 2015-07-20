class UpdateServices < ActiveRecord::Migration
  def up

    Setting.create_or_update(
      title: 'Image Service',
      name: 'image_backend',
      area: 'System::Services',
      description: 'Defines the backend for user and organization image lookups.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'image_backend',
            tag: 'select',
            options: {
              '' => '-',
              'Service::Image::Zammad' => 'Zammad Image Service',
            },
          },
        ],
      },
      state: 'Service::Image::Zammad',
      preferences: { prio: 1 },
      frontend: false
    )

    Setting.create_or_update(
      title: 'Geo IP Service',
      name: 'geo_ip_backend',
      area: 'System::Services',
      description: 'Defines the backend for geo IP lookups. Show also location of an IP address if an IP address is shown.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'geo_ip_backend',
            tag: 'select',
            options: {
              '' => '-',
              'Service::GeoIp::Zammad' => 'Zammad GeoIP Service',
            },
          },
        ],
      },
      state: 'Service::GeoIp::Zammad',
      preferences: { prio: 2 },
      frontend: false
    )

    Setting.create_or_update(
      title: 'Geo Location Service',
      name: 'geo_location_backend',
      area: 'System::Services',
      description: 'Defines the backend for geo location lookups to store geo locations for addresses.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'geo_location_backend',
            tag: 'select',
            options: {
              '' => '-',
              'Service::GeoLocation::Gmaps' => 'Google Maps',
            },
          },
        ],
      },
      state: 'Service::GeoLocation::Gmaps',
      preferences: { prio: 3 },
      frontend: false
    )
  end
end

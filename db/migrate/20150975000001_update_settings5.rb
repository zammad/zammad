class UpdateSettings5 < ActiveRecord::Migration
  def up
    Setting.create_or_update(
      title: 'Geo Calendar Service',
      name: 'geo_calendar_backend',
      area: 'System::Services',
      description: 'Defines the backend for geo calendar lookups. Used for inital calendar succession.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'geo_calendar_backend',
            tag: 'select',
            options: {
              '' => '-',
              'Service::GeoCalendar::Zammad' => 'Zammad GeoCalendar Service',
            },
          },
        ],
      },
      state: 'Service::GeoCalendar::Zammad',
      preferences: { prio: 2 },
      frontend: false
    )
    Calendar.init_setup
  end
end

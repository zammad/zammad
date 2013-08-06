class UpdateGeo < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      :title       => 'Geo Location Backend',
      :name        => 'geo_backend',
      :area        => 'System::Geo',
      :description => 'Defines the backend for geo location lookups.',
      :options     => {
        :form => [
          {
            :display  => '',
            :null     => true,
            :name     => 'geo_backend', 
            :tag      => 'select',
            :options  => {
              '' => '-',
              'Gmaps' => 'Google Maps',
            },
          },
        ],
      },
      :state    => 'Gmaps',
      :frontend => true
    )
  end
  def down
  end
end


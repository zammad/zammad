class FixedTranslation2 < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    settings_update = [
      {
        'name'        => 'http_type',
        'title'       => 'HTTP type',
        'description' => 'Define the http protocol of your instance.',
      },
    ]

    settings_update.each { |setting|
      fetched_setting = Setting.find_by(name: setting['name'])
      next if !fetched_setting

      if setting['title']
        fetched_setting.title = setting['title']
      end

      if setting['description']
        fetched_setting.description = setting['description']
      end

      fetched_setting.save!
    }

    Translation.load

  end
end


class UpdateActivityStream < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')
    ActivityStream.destroy_all
    add_column :activity_streams, :permission_id, :integer, null: true
    remove_column :activity_streams, :role_id

    ActivityStream.connection.schema_cache.clear!
    ActivityStream.reset_column_information

    Setting.create_or_update(
      title: 'sipgate.io integration',
      name: 'sipgate_integration',
      area: 'Integration::Switch',
      description: 'Define if sipgate.io (http://www.sipgate.io) is enabled or not.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'sipgate_integration',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: false,
      preferences: { prio: 1, trigger: ['menu:render', 'cti:reload'] },
      frontend: false
    )
  end
end

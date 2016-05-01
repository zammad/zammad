class AddSipgateIntegration < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
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
      preferences: { prio: 1 },
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'sipgate.io config',
      name: 'sipgate_config',
      area: 'Integration::Sipgate',
      description: 'Define the sipgate.io config.',
      options: {},
      state: {},
      frontend: false,
      preferences: { prio: 2 },
    )
  end
end

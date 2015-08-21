class UpdateModelSearchable < ActiveRecord::Migration
  def up

    Setting.create_if_not_exists(
      title: 'Define searchable models.',
      name: 'models_searchable',
      area: 'Models::Base',
      description: 'Define the models which can be searched for.',
      options: {},
      state: [],
      frontend: false,
    )

  end
end

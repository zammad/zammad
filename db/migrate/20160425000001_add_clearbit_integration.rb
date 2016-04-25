class AddClearbitIntegration < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'Clearbit integration',
      name: 'clearbit_integration',
      area: 'Integration::Switch',
      description: 'Define if Clearbit (http://www.clearbit.com) is enabled or not.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'clearbit_integration',
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
      title: 'Clearbit config',
      name: 'clearbit_config',
      area: 'Integration::Clearbit',
      description: 'Define the Clearbit config.',
      options: {},
      state: {},
      frontend: false,
      preferences: { prio: 2 },
    )
    Setting.create_if_not_exists(
      title: 'Define transaction backend.',
      name: '9000_clearbit_enrichment',
      area: 'Transaction::Backend',
      description: 'Define the transaction backend which will enrich customer and organization informations from (http://www.clearbit.com).',
      options: {},
      state: 'Transaction::ClearbitEnrichment',
      frontend: false
    )
  end
end

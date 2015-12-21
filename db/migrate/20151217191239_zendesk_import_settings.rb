class ZendeskImportSettings < ActiveRecord::Migration
  def change

    Setting.create_if_not_exists(
      title: 'Import Endpoint',
      name: 'import_zendesk_endpoint',
      area: 'Import::Zendesk',
      description: 'Defines Zendesk endpoint to import users, ticket, states and articles.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'import_zendesk_endpoint',
            tag: 'input',
          },
        ],
      },
      state: 'https://yours.zendesk.com/api/v2',
      frontend: false
    )

    Setting.create_if_not_exists(
      title: 'Import Key for requesting the Zendesk API',
      name: 'import_zendesk_endpoint_key',
      area: 'Import::Zendesk',
      description: 'Defines Zendesk endpoint auth key.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'import_zendesk_endpoint_key',
            tag: 'input',
          },
        ],
      },
      state: '',
      frontend: false
    )

    Setting.create_if_not_exists(
      title: 'Import User for requesting the Zendesk API',
      name: 'import_zendesk_endpoint_username',
      area: 'Import::Zendesk',
      description: 'Defines Zendesk endpoint auth key.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'import_zendesk_endpoint_username',
            tag: 'input',
          },
        ],
      },
      state: '',
      frontend: false
    )
  end
end

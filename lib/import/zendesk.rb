require 'base64'
require 'zendesk_api'

module Import
end
module Import::Zendesk
  extend Import::Helper
  extend Import::Zendesk::Async
  extend Import::Zendesk::ImportStats

  # rubocop:disable Style/ModuleFunction
  extend self

  def start
    log 'Start import...'

    checks

    Import::Zendesk::GroupFactory.import(client.groups)

    Import::Zendesk::OrganizationFieldFactory.import(client.organization_fields)
    Import::Zendesk::OrganizationFactory.import(client.organizations)

    Import::Zendesk::UserFieldFactory.import(client.user_fields)
    Import::Zendesk::UserFactory.import(client.users)

    Import::Zendesk::TicketFieldFactory.import(client.ticket_fields)
    Import::Zendesk::TicketFactory.import(client.tickets)

    # TODO
    Setting.set( 'system_init_done', true )
    Setting.set( 'import_mode', false )

    true
  end

  def connection_test
    Import::Zendesk::Requester.connection_test
  end

  private

  def client
    Import::Zendesk::Requester.client
  end

  def checks
    check_import_mode
    connection_test
  end
end

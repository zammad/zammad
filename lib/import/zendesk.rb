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
    Import::Zendesk::TicketFactory.import(all_tickets)

    # TODO
    Setting.set( 'system_init_done', true )
    Setting.set( 'import_mode', false )

    true
  end

  def connection_test
    Import::Zendesk::Requester.connection_test
  end

  private

  # this special ticket logic is needed since Zendesk archives tickets
  # after 120 days and doesn't return them via the client.tickets
  # endpoint as described here:
  # https://github.com/zammad/zammad/issues/558#issuecomment-267951351
  # the proper way is to use the 'incremental' endpoint which is not available
  # via the ruby gem yet but a pull request is pending:
  # https://github.com/zendesk/zendesk_api_client_rb/pull/287
  # the following workaround is needed to use this functionality
  def all_tickets
    ZendeskAPI::Collection.new(
      client,
      ZendeskAPI::Ticket,
      path: 'incremental/tickets?start_time=1'
    )
  end

  def client
    Import::Zendesk::Requester.client
  end

  def checks
    check_import_mode
    check_system_init_done
    connection_test
  end
end

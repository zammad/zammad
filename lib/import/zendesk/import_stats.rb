module Import
  module Zendesk
    module ImportStats
      # rubocop:disable Style/ModuleFunction
      extend self

      def current_state

        data = statistic

        {
          Group: {
            done: ::Group.count,
            total: data['Groups'] || 0,
          },
          Organization: {
            done: ::Organization.count,
            total: data['Organizations'] || 0,
          },
          User: {
            done: ::User.count,
            total: data['Users'] || 0,
          },
          Ticket: {
            done: ::Ticket.count,
            total: data['Tickets'] || 0,
          },
        }
      end

      def statistic

        # check cache
        cache = Cache.get('import_zendesk_stats')
        return cache if cache

        # retrive statistic
        result = {
          'Tickets'            => 0,
          'TicketFields'       => 0,
          'UserFields'         => 0,
          'OrganizationFields' => 0,
          'Groups'             => 0,
          'Organizations'      => 0,
          'Users'              => 0,
          'GroupMemberships'   => 0,
          'Macros'             => 0,
          'Views'              => 0,
          'Automations'        => 0,
        }

        result.each { |object, _score|
          result[ object ] = Import::Zendesk::Requester.client.send( object.underscore.to_sym ).count!
        }

        Cache.write('import_zendesk_stats', result)
        result
      end
    end
  end
end

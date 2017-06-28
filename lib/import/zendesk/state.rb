module Import
  module Zendesk
    class State

      MAPPING = {
        'pending' => 'pending reminder',
        'solved'  => 'closed',
        'deleted' => 'removed',
      }.freeze

      class << self

        def lookup(ticket)
          remote_state = ticket.status
          @mapping ||= {}
          if @mapping[ remote_state ]
            return @mapping[ remote_state ]
          end
          @mapping[ remote_state ] = ::Ticket::State.lookup( name: map( remote_state ) )
        end

        private

        def map(state)
          MAPPING.fetch(state, state)
        end
      end
    end
  end
end

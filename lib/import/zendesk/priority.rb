module Import
  module Zendesk
    class Priority

      MAPPING = {
        'low'    => '1 low',
        nil      => '2 normal',
        'normal' => '2 normal',
        'high'   => '3 high',
        'urgent' => '3 high',
      }.freeze

      class << self

        def lookup(ticket)
          remote_priority = ticket.priority
          @mapping ||= {}
          if @mapping[ remote_priority ]
            return @mapping[ remote_priority ]
          end
          @mapping[ remote_priority ] = ::Ticket::Priority.lookup( name: map(remote_priority) )
        end

        private

        def map(priority)
          MAPPING.fetch(priority, MAPPING[nil])
        end
      end
    end
  end
end

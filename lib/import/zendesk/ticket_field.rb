module Import
  module Zendesk
    class TicketField < Import::Zendesk::ObjectField

      private

      def remote_name(ticket_field)
        ticket_field.title
      end
    end
  end
end

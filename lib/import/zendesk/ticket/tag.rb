module Import
  module Zendesk
    class Ticket
      class Tag
        def initialize(tag, local_ticket, zendesk_ticket)
          ::Tag.tag_add(
            object:        'Ticket',
            o_id:          local_ticket.id,
            item:          tag.id,
            created_by_id: Import::Zendesk::UserFactory.local_id(zendesk_ticket.requester_id) || 1,
          )
        end
      end
    end
  end
end

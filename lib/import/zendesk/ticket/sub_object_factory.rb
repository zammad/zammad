module Import
  module Zendesk
    class Ticket
      module SubObjectFactory
        # we need to loop over each instead of all!
        # so we can use the default import factory here
        include Import::Factory

        private

        def create_instance(record, *args)

          local_ticket   = args[0]
          zendesk_ticket = args[1]

          backend_class(record).new(record, local_ticket, zendesk_ticket)
        end
      end
    end
  end
end

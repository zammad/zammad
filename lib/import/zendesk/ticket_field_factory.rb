module Import
  module Zendesk
    module TicketFieldFactory
      extend Import::Zendesk::BaseFactory
      extend Import::Zendesk::LocalIDMapperHook

      MAPPING = {
        'subject'        => 'title',
        'description'    => 'note',
        'status'         => 'state_id',
        'tickettype'     => 'type',
        'priority'       => 'priority_id',
        'basic_priority' => 'priority_id',
        'group'          => 'group_id',
        'assignee'       => 'owner_id',
      }.freeze

      # rubocop:disable Style/ModuleFunction
      extend self

      def skip?(field, *_args)
        # check if the Ticket object already has a same named column / attribute
        # so we want to skip instead of importing it
        Ticket.column_names.include?( local_attribute(field) )
      end

      private

      def local_attribute(field)
        MAPPING.fetch(field.type, field.type)
      end
    end
  end
end

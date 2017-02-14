module Import
  module OTRS
    module StateFactory
      extend Import::TransactionFactory

      # rubocop:disable Style/ModuleFunction
      extend self

      def pre_import_hook(_records, *_args)
        backup
      end

      def backup
        # rename states to handle not uniq issues
        ::Ticket::State.all.each { |state|
          state.name = state.name + '_tmp'
          state.save
        }
      end

      def import_loop(records, *_args, &import_block)
        super
        update_ticket_state
        update_ticket_pending_time
      end

      def update_ticket_state
        agent_new = ::Ticket::State.where(
          state_type_id: ::Ticket::StateType.where.not(name: %w(merged removed))
        ).pluck(:id)

        agent_edit = ::Ticket::State.where(
          state_type_id: ::Ticket::StateType.where.not(name: %w(new merged removed))
        ).pluck(:id)

        customer_new = ::Ticket::State.where(
          state_type_id: ::Ticket::StateType.where.not(name: %w(new closed))
        ).pluck(:id)

        customer_edit = ::Ticket::State.where(
          state_type_id: ::Ticket::StateType.where.not(name: %w(open closed))
        ).pluck(:id)

        ticket_state_id = ::ObjectManager::Attribute.get(
          object: 'Ticket',
          name:   'state_id',
        )

        ticket_state_id[:data_option][:filter]               = agent_new
        ticket_state_id[:screens][:create_middle][:Customer] = customer_new
        ticket_state_id[:screens][:edit][:Agent]             = agent_edit
        ticket_state_id[:screens][:edit][:Customer]          = customer_edit

        update_ticket_attribute(ticket_state_id)
      end

      def update_ticket_pending_time
        pending_state_ids = ::Ticket::State.where(
          state_type_id: ::Ticket::StateType.where(name: ['pending reminder', 'pending action'])
        ).pluck(:id)

        ticket_pending_time = ::ObjectManager::Attribute.get(
          object: 'Ticket',
          name:   'pending_time',
        )

        ticket_pending_time[:data_option][:required_if][:state_id] = pending_state_ids
        ticket_pending_time[:data_option][:required_if][:state_id] = pending_state_ids

        update_ticket_attribute(ticket_pending_time)
      end

      def update_ticket_attribute(attribute)
        ::ObjectManager::Attribute.add(
          object_lookup_id: attribute[:object_lookup_id],
          name:             attribute[:name],
          display:          attribute[:display],
          data_type:        attribute[:data_type],
          data_option:      attribute[:data_option],
          active:           attribute[:active],
          screens:          attribute[:screens],
          force:            true # otherwise _id as a name is not permitted
        )
      end
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
        ::Ticket::State.all.each do |state|
          state.name = "#{state.name}_tmp"
          state.save
        end
      end

      def import_loop(records, *_args, &)
        super

        update_pending_auto_states
        update_attribute_settings
      end

      def update_pending_auto_states
        ::Ticket::State.where(state_type_id: ::Ticket::StateType.where(name: 'pending action').map(&:id)).each do |state|
          close_state_name = state.name == 'pending auto close-' ? 'closed unsuccessful' : 'closed successful'

          update_state_with_next_state_id(state, close_state_name)
        end
      end

      def update_state_with_next_state_id(state, close_state_name)
        state.next_state_id = ::Ticket::State.find_by(name: close_state_name)&.id

        if state.next_state_id.blank?
          state.next_state_id = ::Ticket::StateType.find_by(name: 'closed')&.first&.id
        end

        state.save
      end

      def update_attribute_settings
        return if Import::OTRS.diff?

        update_attribute
        update_ticket_attributes
      end

      def update_attribute
        update_default_create
        update_default_follow_up
      end

      def update_default_create
        state = ::Ticket::State.find_by(
          name:   Import::OTRS::SysConfigFactory.postmaster_default_lookup(:state_default_create),
          active: true
        )
        return if !state

        state.default_create = true
        state.save!
      end

      def update_default_follow_up
        state = ::Ticket::State.find_by(
          name:   Import::OTRS::SysConfigFactory.postmaster_default_lookup(:state_default_follow_up),
          active: true
        )
        return if !state

        state.default_follow_up = true
        state.save!
      end

      def update_ticket_attributes
        update_ticket_state
        reseed_dependent_objects
      end

      def update_ticket_state
        agent_new = fetch_ticket_states(%w[merged removed])
        agent_edit = fetch_ticket_states(%w[new merged removed])
        customer_new = fetch_ticket_states(%w[ew closed])
        customer_edit = fetch_ticket_states(%w[open closed])

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

      def fetch_ticket_states(ignore_state_names)
        ::Ticket::State.where(
          state_type_id: ::Ticket::StateType.where.not(name: ignore_state_names)
        ).pluck(:id)
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

      def reseed_dependent_objects
        Overview.reseed
        Trigger.reseed
        Macro.reseed

        # we don't have to re-seed the ObjectManager
        # Attributes since they contain the already
        # imported DynamicFields which will be lost
        ObjectManager::Attribute.seed
      end
    end
  end
end

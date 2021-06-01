# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class State
      include Import::Helper
      include Import::OTRS::Helper

      MAPPING = {
        ChangeTime: :updated_at,
        CreateTime: :created_at,
        CreateBy:   :created_by_id,
        ChangeBy:   :updated_by_id,
        Name:       :name,
        ID:         :id,
        ValidID:    :active,
        Comment:    :note,
      }.freeze

      def initialize(state)
        import(state)
      end

      private

      def import(state)
        create_or_update(map(state))
      end

      def create_or_update(state)
        return if updated?(state)

        create(state)
      end

      def updated?(state)
        @local_state = ::Ticket::State.find_by(id: state[:id])
        return false if !@local_state

        log "update Ticket::State.find_by(id: #{state[:id]})"
        @local_state.update!(state)
        true
      end

      def create(state)
        log "add Ticket::State.find_by(id: #{state[:id]})"
        @local_state    = ::Ticket::State.new(state)
        @local_state.id = state[:id]
        @local_state.save
        reset_primary_key_sequence('ticket_states')
      end

      def map(state)
        {
          created_by_id: 1,
          updated_by_id: 1,
          active:        active?(state),
          state_type_id: state_type_id(state)
        }
          .merge(from_mapping(state))
      end

      def state_type_id(state)
        map_type(state)
        ::Ticket::StateType.lookup(name: state['TypeName']).id
      end

      def map_type(state)
        return if state['TypeName'] != 'pending auto'

        state['TypeName'] = 'pending action'
      end
    end
  end
end

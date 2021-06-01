# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class History
      class StateUpdate < Import::OTRS::History
        def init_callback(history)
          data = history['Name']
          # "%%new%%open%%"
          from = nil
          to   = nil
          if data =~ %r{%%(.+?)%%(.+?)%%}
            from    = $1
            to      = $2
            state_from = ::Ticket::State.lookup(name: from)
            state_to   = ::Ticket::State.lookup(name: to)
            if state_from
              from_id = state_from.id
            end
            if state_to
              to_id = state_to.id
            end
          end
          @history_attributes = {
            id:                history['HistoryID'],
            o_id:              history['TicketID'],
            history_type:      'updated',
            history_object:    'Ticket',
            history_attribute: 'state',
            value_from:        from,
            id_from:           from_id,
            value_to:          to,
            id_to:             to_id,
            created_at:        history['CreateTime'],
            created_by_id:     history['CreateBy']
          }
        end
      end
    end
  end
end

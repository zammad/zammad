# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class History
      class PriorityUpdate < Import::OTRS::History
        def init_callback(history)
          data = history['Name']
          # "%%3 normal%%3%%5 very high%%5"
          from = nil
          to   = nil
          if data =~ %r{%%(.+?)%%(.+?)%%(.+?)%%(.+?)$}
            from    = $1
            from_id = $2
            to      = $3
            to_id   = $4
          end
          @history_attributes = {
            id:                history['HistoryID'],
            o_id:              history['TicketID'],
            history_type:      'updated',
            history_object:    'Ticket',
            history_attribute: 'priority',
            value_from:        from,
            value_to:          to,
            id_from:           from_id,
            id_to:             to_id,
            created_at:        history['CreateTime'],
            created_by_id:     history['CreateBy']
          }
        end
      end
    end
  end
end

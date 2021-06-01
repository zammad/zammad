# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class History
      class Article < Import::OTRS::History
        def init_callback(history)
          @history_attributes = {
            id:                     history['HistoryID'],
            o_id:                   history['ArticleID'],
            history_type:           'created',
            history_object:         'Ticket::Article',
            related_o_id:           history['TicketID'],
            related_history_object: 'Ticket',
            created_at:             history['CreateTime'],
            created_by_id:          history['CreateBy']
          }
        end
      end
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Ticket::TimeAccounting::Assets
  extend ActiveSupport::Concern

  def assets(data)
    app_model_ticket_time_accounting = Ticket::TimeAccounting.to_app_model

    if !data[ app_model_ticket_time_accounting ]
      data[ app_model_ticket_time_accounting ] = {}
    end
    return data if data[ app_model_ticket_time_accounting ][ id ]

    data[ app_model_ticket_time_accounting ][ id ] = attributes_with_association_ids.slice('id', 'ticket_id', 'ticket_article_id', 'time_unit', 'type_id')

    data
  end
end

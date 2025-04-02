# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Report::BaseSql < Report::Base
  TICKET_STATE_ATTRIBUTE = 'ticket_state.state_type_id'.freeze
end

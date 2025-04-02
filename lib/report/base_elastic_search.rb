# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Report::BaseElasticSearch < Report::Base
  TICKET_STATE_ATTRIBUTE = 'state.state_type_id'.freeze
end

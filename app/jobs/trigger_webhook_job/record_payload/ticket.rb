# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TriggerWebhookJob::RecordPayload::Ticket < TriggerWebhookJob::RecordPayload::Base
  ASSOCIATIONS = %i[owner customer created_by updated_by organization priority group].freeze
end

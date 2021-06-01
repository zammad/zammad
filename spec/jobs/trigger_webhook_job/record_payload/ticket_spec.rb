# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'jobs/trigger_webhook_job/record_payload/base_example'

RSpec.describe TriggerWebhookJob::RecordPayload::Ticket do
  it_behaves_like 'TriggerWebhookJob::RecordPayload backend', :ticket
end

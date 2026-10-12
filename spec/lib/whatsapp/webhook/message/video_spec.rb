# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/whatsapp/webhook/message/media_examples'

RSpec.describe Whatsapp::Webhook::Message::Video, :aggregate_failures, current_user_id: 1 do
  it_behaves_like 'Whatsapp::Webhook::Message media', type: 'video', mime_type: 'video/mp4', extension: 'mp4'
end

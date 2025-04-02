# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChannelsAdmin::WhatsappControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_whatsapp')
end

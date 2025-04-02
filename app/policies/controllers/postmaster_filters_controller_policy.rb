# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::PostmasterFiltersControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!(['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'])
end

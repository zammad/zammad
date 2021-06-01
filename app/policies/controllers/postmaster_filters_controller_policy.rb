# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::PostmasterFiltersControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_email')
end

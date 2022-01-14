# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::HttpLogsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.*')
end

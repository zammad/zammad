# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::CtiControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('cti.agent')
end

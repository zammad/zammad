# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::CtiControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('cti.agent')
end

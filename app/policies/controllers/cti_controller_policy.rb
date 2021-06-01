# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::CtiControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('cti.agent')
end

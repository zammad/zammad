# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::FirstStepsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index test_ticket], to: ['ticket.agent', 'admin']
end

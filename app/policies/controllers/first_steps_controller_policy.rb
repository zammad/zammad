# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::FirstStepsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index test_ticket], to: ['ticket.agent', 'admin']
end

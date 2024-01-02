# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TicketPolicy < ApplicationPolicy
  class FullScope < BaseScope
    ACCESS_TYPE = :full
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketPolicy < ApplicationPolicy
  class OverviewScope < BaseScope
    ACCESS_TYPE = :overview
  end
end

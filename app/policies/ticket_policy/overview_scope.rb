# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketPolicy < ApplicationPolicy
  class OverviewScope < BaseScope
    ACCESS_TYPE = :overview
  end
end

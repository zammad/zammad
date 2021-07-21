# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketPolicy < ApplicationPolicy
  class FullScope < BaseScope
    ACCESS_TYPE = :full
  end
end

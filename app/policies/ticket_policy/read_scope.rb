# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketPolicy < ApplicationPolicy
  class ReadScope < BaseScope
    ACCESS_TYPE = :read
  end
end

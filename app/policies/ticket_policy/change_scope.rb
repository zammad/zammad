# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class TicketPolicy < ApplicationPolicy
  class ChangeScope < BaseScope
    ACCESS_TYPE = :change
  end
end

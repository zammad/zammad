# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Ticket::Priority < ApplicationModel
  self.table_name = 'ticket_priorities'
  validates :name, presence: true
end

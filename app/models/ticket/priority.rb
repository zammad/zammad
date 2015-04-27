# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
# rubocop:disable ClassAndModuleChildren
class Ticket::Priority < ApplicationModel
  self.table_name = 'ticket_priorities'
  validates     :name, presence: true
end

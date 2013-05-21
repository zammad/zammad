class Ticket::Priority < ApplicationModel
  self.table_name = 'ticket_priorities'
  validates     :name, :presence => true
end
# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Ticket::TimeAccounting < ApplicationModel

  belongs_to :ticket, optional: true
  belongs_to :ticket_article, class_name: 'Ticket::Article', inverse_of: :ticket_time_accounting, optional: true

  after_create :update_time_units
  after_update :update_time_units

  def update_time_units
    self.class.update_ticket(ticket)
  end

  def self.update_ticket(ticket)
    time_units = total(ticket)
    return if ticket.time_unit.to_d == time_units

    ticket.time_unit = time_units
    ticket.save!
  end

  def self.total(ticket)
    ticket.ticket_time_accounting.sum(:time_unit)
  end
end

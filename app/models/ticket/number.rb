# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Ticket::Number
  include ApplicationLib

=begin

generate new ticket number

  result = Ticket::Number.generate

returns

  result = "1234556" # new ticket number

=end

  def self.generate
    49_999.times do
      number = adapter.generate
      return number if !Ticket.exists?(number: number)
    end

    raise "Can't generate new ticket number!"
  end

=begin

check if string contains a valid ticket number

  result = Ticket::Number.check('some string [Ticket#123456]')

returns

  result = ticket # Ticket model of ticket with matching ticket number

=end

  def self.check(string)
    adapter.check(string)
  end

  # load backend based on config
  def self.adapter
    Setting.get('ticket_number')&.constantize ||
      raise('Missing ticket_number setting option')
  end
end

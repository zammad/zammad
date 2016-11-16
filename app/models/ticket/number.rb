# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Ticket::Number
  include ApplicationLib

=begin

generate new ticket number

  result = Ticket::Number.generate

returns

  result = "1234556" # new ticket number

=end

  def self.generate

    # generate number
    49_999.times {
      number = adapter.generate
      ticket = Ticket.find_by(number: number)
      return number if !ticket
    }
    raise "Can't generate new ticket number!"
  end

=begin

check if string contrains a valid ticket number

  result = Ticket::Number.check('some string [Ticket#123456]')

returns

  result = ticket # Ticket model of ticket with matching ticket number

=end

  def self.check(string)
    adapter.check(string)
  end

  def self.adapter

    # load backend based on config
    adapter_name = Setting.get('ticket_number')
    if !adapter_name
      raise 'Missing ticket_number setting option'
    end
    adapter = load_adapter(adapter_name)
    if !adapter
      raise "Can't load ticket_number adapter '#{adapter_name}'"
    end
    adapter
  end
end

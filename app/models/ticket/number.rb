# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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

    raise __('The new ticket number could not be generated.')
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
      raise(__("The setting 'ticket_number' was not configured."))
  end
end

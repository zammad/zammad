# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Number::Increment
  module_function

  def generate

    # get config
    config = Setting.get('ticket_number_increment')

    # read counter
    min_digs = config[:min_size] || 4
    counter_increment = nil
    Ticket::Counter.transaction do
      counter = Ticket::Counter.where(generator: 'Increment').lock(true).first
      if !counter
        counter = Ticket::Counter.new(generator: 'Increment', content: '0')
      end
      counter_increment = counter.content.to_i

      # increase counter
      counter_increment += 1

      # store new counter value
      counter.content = counter_increment.to_s
      counter.save
    end

    # fill up number counter
    if config[:checksum]
      min_digs = min_digs.to_i - 1
    end
    fillup = Setting.get('system_id').to_s || '1'
    99.times do

      next if (fillup.length.to_i + counter_increment.to_s.length.to_i) >= min_digs.to_i

      fillup = fillup + '0'
    end
    number = fillup.to_s + counter_increment.to_s

    # calculate a checksum
    # The algorithm to calculate the checksum is derived from the one
    # Deutsche Bundesbahn (german railway company) uses for calculation
    # of the check digit of their vehikel numbering.
    # The checksum is calculated by alternately multiplying the digits
    # with 1 and 2 and adding the resulsts from left to right of the
    # vehikel number. The modulus to 10 of this sum is substracted from
    # 10. See: http://www.pruefziffernberechnung.de/F/Fahrzeugnummer.shtml
    # (german)
    if config[:checksum]
      chksum = 0
      mult   = 1
      (1..number.length).each do |i|
        digit = number.to_s[i, 1]
        chksum = chksum + (mult * digit.to_i)
        mult += 1
        if mult == 3
          mult = 1
        end
      end
      chksum %= 10
      chksum = 10 - chksum
      if chksum == 10
        chksum = 1
      end
      number += chksum.to_s
    end
    number
  end

  def check(string)
    return if string.blank?

    # get config
    system_id           = Setting.get('system_id') || ''
    ticket_hook         = Setting.get('ticket_hook')
    ticket_hook_divider = Setting.get('ticket_hook_divider') || ''
    ticket              = nil

    if Setting.get('ticket_number_ignore_system_id') == true
      system_id = ''
    end

    # probe format
    # NOTE: we use `(?<=\W|^)` at the start of the regular expressions below
    # because `\b` fails when ticket_hook begins with a non-word character (like '#')
    string.scan(/(?<=\W|^)#{Regexp.quote(ticket_hook)}#{Regexp.quote(ticket_hook_divider)}(#{system_id}\d{2,48})\b/i) do
      ticket = Ticket.find_by(number: $1)
      break if ticket
    end
    if !ticket
      string.scan(/(?<=\W|^)#{Regexp.quote(ticket_hook)}\s{0,2}(#{system_id}\d{2,48})\b/i) do
        ticket = Ticket.find_by(number: $1)
        break if ticket
      end
    end
    ticket
  end
end

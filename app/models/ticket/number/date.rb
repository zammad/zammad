# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module Ticket::Number::Date
  module_function

  def generate

    # get config
    config = Setting.get('ticket_number_date')

    t = Time.zone.now
    date = t.strftime('%Y-%m-%d')

    # read counter
    counter_increment = nil
    Ticket::Counter.transaction do
      counter = Ticket::Counter.where(generator: 'Date').lock(true).first
      if !counter
        counter = Ticket::Counter.new(generator: 'Date', content: '0')
      end

      # increase counter
      counter_increment, date_file = counter.content.to_s.split(';')
      counter_increment = if date_file == date
                            counter_increment.to_i + 1
                          else
                            1
                          end

      # store new counter value
      counter.content = counter_increment.to_s + ';' + date
      counter.save
    end

    system_id = Setting.get('system_id') || ''
    number = t.strftime('%Y%m%d') + system_id.to_s + format('%04d', counter_increment)

    # calculate a checksum
    # The algorithm to calculate the checksum is derived from the one
    # Deutsche Bundesbahn (german railway company) uses for calculation
    # of the check digit of their vehikel numbering.
    # The checksum is calculated by alternately multiplying the digits
    # with 1 and 2 and adding the resulsts from left to right of the
    # vehikel number. The modulus to 10 of this sum is substracted from
    # 10. See: http://www.pruefziffernberechnung.de/F/Fahrzeugnummer.shtml
    # (german)

    # fix for https://github.com/zammad/zammad/issues/413 - can be removed later
    if config.class == FalseClass || config.class == TrueClass
      config = {
        checksum: config
      }
    end

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
    string.scan(/(?<=\W|^)#{Regexp.quote(ticket_hook)}#{Regexp.quote(ticket_hook_divider)}(\d{4,10}#{system_id}\d{2,40})\b/i) do
      ticket = Ticket.find_by(number: $1)
      break if ticket
    end
    if !ticket
      string.scan(/(?<=\W|^)#{Regexp.quote(ticket_hook)}\s{0,2}(\d{4,10}#{system_id}\d{2,40})\b/i) do
        ticket = Ticket.find_by(number: $1)
        break if ticket
      end
    end
    ticket
  end
end

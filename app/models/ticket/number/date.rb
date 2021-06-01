# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Number::Date
  extend Ticket::Number::Base

  def self.generate
    date = Time.zone.now.strftime('%F')

    counter = Ticket::Counter.create_with(content: '0')
                             .find_or_create_by(generator: 'Date')

    counter.with_lock do
      counter_increment = if counter.content.end_with?(date)
                            counter.content.split(';').first.to_i.next
                          else
                            1
                          end

      counter.update(content: "#{counter_increment};#{date}")
    end

    number  = date.delete('-') + Setting.get('system_id').to_s + format('%<counter>04d', counter: counter.content.split(';').first)
    number += checksum(number) if config[:checksum]

    number
  end

  def self.check(string)
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
    string.scan(%r{(?<=\W|^)#{Regexp.quote(ticket_hook)}#{Regexp.quote(ticket_hook_divider)}(\d{4,10}#{system_id}\d{2,40})\b}i) do
      ticket = Ticket.find_by(number: $1)
      break if ticket
    end
    if !ticket
      string.scan(%r{(?<=\W|^)#{Regexp.quote(ticket_hook)}\s{0,2}(\d{4,10}#{system_id}\d{2,40})\b}i) do
        ticket = Ticket.find_by(number: $1)
        break if ticket
      end
    end
    ticket
  end

  def self.config
    config = Setting.get('ticket_number_date')
    return config if !config.in?([true, false])

    # fix for https://github.com/zammad/zammad/issues/413 - can be removed later
    { checksum: config }
  end
  private_class_method :config
end

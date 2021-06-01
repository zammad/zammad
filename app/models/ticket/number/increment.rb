# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Number::Increment
  extend Ticket::Number::Base

  def self.generate
    counter = Ticket::Counter.create_with(content: '0')
                             .find_or_create_by(generator: 'Increment')

    counter.with_lock do
      counter.update(content: counter.content.to_i.next.to_s)
    end

    # fill up number counter
    head = (Setting.get('system_id') || 1).to_s
    tail = counter.content

    padding_length  = (config[:min_size] || 4).to_i - head.length - tail.length
    padding_length -= 1 if config[:checksum]
    padding_length  = 0 if padding_length.negative?
    padding_length  = 99 if padding_length > 99

    number  = head + ('0' * padding_length) + tail
    number += checksum(number) if config[:checksum]

    number
  end

  def self.check(string)
    return if string.blank?

    # get config
    system_id           = Setting.get('ticket_number_ignore_system_id') ? '' : Setting.get('system_id').to_s
    ticket_hook         = Setting.get('ticket_hook')
    ticket_hook_divider = Setting.get('ticket_hook_divider').to_s
    ticket              = nil

    # probe format
    # NOTE: we use `(?<=\W|^)` at the start of the regular expressions below
    # because `\b` fails when ticket_hook begins with a non-word character (like '#')
    string.scan(%r{(?<=\W|^)#{Regexp.quote(ticket_hook)}#{Regexp.quote(ticket_hook_divider)}(#{system_id}\d{2,48})\b}i) do
      ticket = Ticket.find_by(number: $1)
      break if ticket
    end

    if !ticket
      string.scan(%r{(?<=\W|^)#{Regexp.quote(ticket_hook)}\s{0,2}(#{system_id}\d{2,48})\b}i) do
        ticket = Ticket.find_by(number: $1)
        break if ticket
      end
    end

    ticket
  end

  def self.config
    Setting.get('ticket_number_increment')
  end
  private_class_method :config
end

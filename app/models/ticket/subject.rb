# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Ticket::Subject

=begin

build new subject with ticket number in there

  ticket = Ticket.find(123)
  prefix_mode = :reply # :forward, nil
  result = ticket.subject_build('some subject', prefix_mode)

returns

  result = "[Ticket#1234567] some subject"

=end

  def subject_build(subject, prefix_mode = nil)

    # clean subject
    subject_parts = [subject_clean(subject)]

    # add hook
    case Setting.get('ticket_hook_position')
    when 'left'
      subject_parts.unshift subject_build_hook
    when 'right'
      subject_parts.push subject_build_hook
    end

    # add prefix
    subject_parts
      .unshift(subject_build_prefix(prefix_mode))
      .compact!

    subject_parts.join ' '
  end

=begin

clean subject remove ticket number and other not needed chars

  ticket = Ticket.find(123)
  result = ticket.subject_clean('[Ticket#1234567] some subject')

returns

  result = "some subject"

=end

  def subject_clean(subject)
    return '' if subject.blank?

    ticket_hook         = Regexp.escape Setting.get('ticket_hook')
    ticket_hook_divider = Regexp.escape Setting.get('ticket_hook_divider')
    ticket_subject_size = Setting.get('ticket_subject_size')

    # remove all possible ticket hook formats with [], () or without any wrapping
    [ ['\[', '\]'], ['\(', '\)'], [''] ].each do |wrapping|
      subject = subject
        .gsub(%r{#{wrapping.first}#{ticket_hook}((: ?)|#{ticket_hook_divider})#{number}#{wrapping.last}(\s+?|)}, '')
    end

    # remove leading "..:\s" and "..[\d+]:\s" e. g. "Re: " or "Re[5]: "
    subject = subject.gsub(%r{^(..(\[\d+\])?:\s)+}, '')

    # resize subject based on config
    if subject.length > ticket_subject_size.to_i
      subject = "#{subject[ 0, ticket_subject_size.to_i ]}[...]"
    end

    subject.strip!
    subject
  end

  private

  def subject_build_hook
    ticket_hook         = Setting.get('ticket_hook')
    ticket_hook_divider = Setting.get('ticket_hook_divider')

    "[#{ticket_hook}#{ticket_hook_divider}#{number}]"
  end

  def subject_build_prefix(prefix_mode)
    prefix = case prefix_mode
             when 'reply'
               Setting.get('ticket_subject_re')
             when 'forward'
               Setting.get('ticket_subject_fwd')
             end

    prefix.present? ? "#{prefix}:" : nil
  end
end

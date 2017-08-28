# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module Ticket::Subject

=begin

build new subject with ticket number in there

  ticket = Ticket.find(123)
  result = ticket.subject_build('some subject', is_reply_true_false)

returns

  result = "[Ticket#1234567] some subject"

=end

  def subject_build(subject, is_reply = false)

    # clena subject
    subject = subject_clean(subject)

    ticket_hook         = Setting.get('ticket_hook')
    ticket_hook_divider = Setting.get('ticket_hook_divider')
    ticket_subject_re   = Setting.get('ticket_subject_re')

    # none position
    if Setting.get('ticket_hook_position') == 'none'
      if is_reply && ticket_subject_re.present?
        subject = "#{ticket_subject_re}: #{subject}"
      end
      return subject
    end

    # right position
    if Setting.get('ticket_hook_position') == 'right'
      if is_reply && ticket_subject_re.present?
        subject = "#{ticket_subject_re}: #{subject}"
      end
      return "#{subject} [#{ticket_hook}#{ticket_hook_divider}#{number}]"
    end

    # left position
    if is_reply && ticket_subject_re.present?
      return "#{ticket_subject_re}: [#{ticket_hook}#{ticket_hook_divider}#{number}] #{subject}"
    end
    "[#{ticket_hook}#{ticket_hook_divider}#{number}] #{subject}"
  end

=begin

clean subject remove ticket number and other not needed chars

  ticket = Ticket.find(123)
  result = ticket.subject_clean('[Ticket#1234567] some subject')

returns

  result = "some subject"

=end

  def subject_clean(subject)
    ticket_hook         = Setting.get('ticket_hook')
    ticket_hook_divider = Setting.get('ticket_hook_divider')
    ticket_subject_size = Setting.get('ticket_subject_size')

    # remove all possible ticket hook formats with []
    subject = subject.gsub(/\[#{ticket_hook}: #{number}\](\s+?|)/, '')
    subject = subject.gsub(/\[#{ticket_hook}:#{number}\](\s+?|)/, '')
    subject = subject.gsub(/\[#{ticket_hook}#{ticket_hook_divider}#{number}\](\s+?|)/, '')

    # remove all possible ticket hook formats without []
    subject = subject.gsub(/#{ticket_hook}: #{number}(\s+?|)/, '')
    subject = subject.gsub(/#{ticket_hook}:#{number}(\s+?|)/, '')
    subject = subject.gsub(/#{ticket_hook}#{ticket_hook_divider}#{number}(\s+?|)/, '')

    # remove leading "..:\s" and "..[\d+]:\s" e. g. "Re: " or "Re[5]: "
    subject = subject.gsub(/^(..(\[\d+\])?:\s)+/, '')

    # resize subject based on config
    if subject.length > ticket_subject_size.to_i
      subject = subject[ 0, ticket_subject_size.to_i ] + '[...]'
    end

    subject.gsub!(/^[[:space:]]+/, '')
    subject.gsub!(/[[:space:]]+$/, '')
    subject
  end
end

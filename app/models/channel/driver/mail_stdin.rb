# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::MailStdin < Channel::EmailParser

=begin

process emails from STDIN

  cat /path/to/mail.eml | rails r 'Channel::Driver::MailStdin.new'

=end

  def initialize
    Rails.logger.info 'read main from STDIN'

    msg = ARGF.read

    process({}, msg)
  end
end

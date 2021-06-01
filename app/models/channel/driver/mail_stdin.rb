# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::MailStdin < Channel::EmailParser

=begin

process emails from STDIN

  cat /path/to/mail.eml | rails r 'Channel::Driver::MailStdin.new'

e. g.

  cat test/data/mail/mail001.box | rails r 'Channel::Driver::MailStdin.new'

e. g. if you want to trust on mail headers

  cat test/data/mail/mail001.box | rails r 'Channel::Driver::MailStdin.new(trusted: true)'

e. g. if you want to process this mail by using a certain inbound channel

  cat test/data/mail/mail001.box | rails r 'Channel::Driver::MailStdin.new(Channel.find(14))'

=end

  def initialize(params = {}) # rubocop:disable Lint/MissingSuper
    Rails.logger.info 'read main from STDIN'

    msg = ARGF.read

    process(params, msg)
  end
end

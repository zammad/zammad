# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::MailStdin < Channel::EmailParser
  def initialize
    Rails.logger.info 'read main from STDIN'

    msg = ARGF.read

    process( {}, msg )
  end
end

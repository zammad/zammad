# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Channel::MailStdin < Channel::EmailParser
  def initialize
    puts "read main from STDIN"

    msg = ARGF.read

    process( {}, msg )
  end
end

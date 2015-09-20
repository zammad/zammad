# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::OutOfOfficeCheck

  def self.run( _channel, mail )

    mail[ 'x-zammad-out-of-office'.to_sym ] = false

    # check ms out of office characteristics
    return if !mail[ 'x-auto-response-suppress'.to_sym ]
    return if mail[ 'x-auto-response-suppress'.to_sym ] !~ /all/i
    return if !mail[ 'x-ms-exchange-inbox-rules-loop'.to_sym ]

    mail[ 'x-zammad-out-of-office'.to_sym ] = true

  end
end

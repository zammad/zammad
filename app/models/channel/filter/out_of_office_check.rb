# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::OutOfOfficeCheck

  def self.run(_channel, mail)

    mail[ 'x-zammad-out-of-office'.to_sym ] = false

    # check ms out of office characteristics
    if mail[ 'x-auto-response-suppress'.to_sym ]
      return if !mail[ 'x-auto-response-suppress'.to_sym ].match?(/all/i)
      return if !mail[ 'x-ms-exchange-inbox-rules-loop'.to_sym ]

      mail[ 'x-zammad-out-of-office'.to_sym ] = true
      return
    end

    if mail[ 'auto-submitted'.to_sym ]

      # check zimbra out of office characteristics
      if mail[ 'auto-submitted'.to_sym ].match?(/vacation/i)
        mail[ 'x-zammad-out-of-office'.to_sym ] = true
      end

      # check cloud out of office characteristics
      if mail[ 'auto-submitted'.to_sym ].match?(/auto-replied;\sowner-email=/i)
        mail[ 'x-zammad-out-of-office'.to_sym ] = true
      end

      # gmail check out of office characteristics
      if mail[ 'auto-submitted'.to_sym ] =~ /auto-replied/i && mail[ 'subject'.to_sym ] =~ /vacation/i
        mail[ 'x-zammad-out-of-office'.to_sym ] = true
      end

      return
    end

    true
  end

end

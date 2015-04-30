# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'net/pop'

class Channel::POP3 < Channel::EmailParser

  def fetch (channel, check_type = '', verify_string = '')
    ssl  = true
    port = 995
    if channel[:options].has_key?(:ssl) && channel[:options][:ssl].to_s == 'false'
      ssl  = false
      port = 110
    end

    puts "fetching pop3 (#{channel[:options][:host]}/#{channel[:options][:user]} port=#{port},ssl=#{ssl})"

    @pop = Net::POP3.new( channel[:options][:host], port )

    # on check, reduce open_timeout to have faster probing
    if check_type == 'check'
      @pop.open_timeout = 4
      @pop.read_timeout = 6
    end

    if ssl
      @pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
    end
    @pop.start( channel[:options][:user], channel[:options][:password] )
    if check_type == 'check'
      puts 'check only mode, fetch no emails'
      disconnect
      return
    elsif check_type == 'verify'
      puts 'verify mode, fetch no emails'
    end

    mails     = @pop.mails
    count     = 0
    count_all = mails.size

    # reverse message order to increase performance
    if check_type == 'verify'
      mails.reverse!
    end

    mails.each do |m|
      count += 1
      puts " - message #{count.to_s}/#{count_all.to_s}"

      # check for verify message
      if check_type == 'verify'
        mail = m.pop
        if mail && mail =~ /#{verify_string}/
          puts " - verify email #{verify_string} found"
          m.delete
          disconnect
          return 'verify ok'
        end
      else

        # delete email from server after article was created
        if process(channel, m.pop)
          m.delete
        end
      end
    end
    disconnect
    if count == 0
      puts ' - no message'
    end
    puts 'done'
  end

  def disconnect

    return if !@pop

    @pop.finish
  end

end

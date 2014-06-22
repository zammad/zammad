# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'net/pop'

class Channel::POP3 < Channel::EmailParser

  def fetch (channel)
    ssl  = false
    port = 110
    if channel[:options][:ssl].to_s == 'true'
      ssl  = true
      port = 995
    end

    puts "fetching pop3 (#{channel[:options][:host]}/#{channel[:options][:user]} port=#{port},ssl=#{ssl})"

    @pop = Net::POP3.new( channel[:options][:host], port )
    if ssl
      @pop.enable_ssl
    end
    @pop.start( channel[:options][:user], channel[:options][:password] )
    count     = 0
    count_all = @pop.mails.size
    @pop.each_mail do |m|
      count += 1
      puts " - message #{count.to_s}/#{count_all.to_s}"

      # delete email from server after article was created
      if process(channel, m.pop)
        m.delete
      end
    end
    disconnect
    if count == 0
      puts " - no message"
    end
    puts "done"
  end

  def disconnect
    if @pop
      @pop.finish
    end
  end

  def send(attr, notification = false)
    channel = Channel.where( :area => 'Email::Outbound', :active => true ).first
    begin
      c = eval 'Channel::' + channel[:adapter] + '.new'
      c.send(attr, channel, notification)
    rescue Exception => e
      puts "can't use " + 'Channel::' + channel[:adapter]
      puts e.inspect
    end
  end
end

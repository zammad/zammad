require 'net/pop'

class Channel::POP3 < Channel::EmailParser
  include UserInfo

  def fetch (channel)
    puts 'fetching pop3'

    pop = Net::POP3.new( channel[:options][:host], 995 )
    pop.enable_ssl
    pop.start( channel[:options][:user], channel[:options][:password] ) 
    count = 0
    pop.each_mail do |m|
      
      # delete email from server after article was created
      if parse(channel, m.pop)
        m.delete
      end
      count += 1
    end
    pop.finish
    puts "#{count.to_s} mails popped. done."
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
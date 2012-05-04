require 'net/pop'

class Channel::POP3 < Channel::EmailParser
  include UserInfo

  def fetch (channel)
    puts "fetching pop3 (#{channel[:options][:host]}/#{channel[:options][:user]})"

    pop = Net::POP3.new( channel[:options][:host], 995 )
    pop.enable_ssl
    pop.start( channel[:options][:user], channel[:options][:password] ) 
    count     = 0
    count_all = pop.mails.size
    pop.each_mail do |m|
      count += 1
      puts " - message #{count.to_s}/#{count_all.to_s}"

      # delete email from server after article was created
      if process(channel, m.pop)
        m.delete
      end
    end
    pop.finish
    if count == 0
      puts " - no message"
    end
    puts "done"
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
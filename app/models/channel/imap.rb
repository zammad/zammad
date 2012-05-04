require 'net/imap'

class Channel::IMAP < Channel::EmailParser
  include UserInfo

  def fetch (channel)
    puts "fetching imap (#{channel[:options][:host]}/#{channel[:options][:user]})"

    imap = Net::IMAP.new(channel[:options][:host], 993, true, nil, false )
    imap.authenticate('LOGIN', channel[:options][:user], channel[:options][:password])
    imap.select('INBOX')
    count     = 0
    count_all = imap.search(['ALL']).count
    imap.search(['ALL']).each do |message_id|
      count += 1
      puts " - message #{count.to_s}/#{count_all.to_s}"
      msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
#      puts msg.to_s

      # delete email from server after article was created      
      if process(channel, msg)
        imap.store(message_id, "+FLAGS", [:Deleted])
      end
    end
    imap.expunge()
    imap.disconnect()
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
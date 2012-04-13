require 'net/imap'

class Channel::IMAP < Channel::EmailParser
  include UserInfo

  def fetch (channel)
    puts 'fetching imap'

    imap = Net::IMAP.new(channel[:options][:host], 993, true )
    imap.authenticate('LOGIN', channel[:options][:user], channel[:options][:password])
    imap.select('INBOX')
    count = 0
    imap.search(['ALL']).each do |message_id|
      msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
#      puts msg.to_s

      # delete email from server after article was created      
      if parse(channel, msg)
        imap.store(message_id, "+FLAGS", [:Deleted])
      end
      count += 1
    end
    imap.expunge()
    imap.disconnect()
    puts "#{count.to_s} mails fetched. done."
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
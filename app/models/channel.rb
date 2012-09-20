class Channel < ApplicationModel
  store :options

  def self.fetch
    channels = Channel.where( 'active = ? AND area LIKE ?', true, '%::Inbound' )
    channels.each { |channel|
      begin
        c = eval 'Channel::' + channel[:adapter] + '.new'
        c.fetch(channel)
      rescue Exception => e
        puts "can't use " + 'Channel::' + channel[:adapter]
        puts e.inspect
      end
    }
  end
end
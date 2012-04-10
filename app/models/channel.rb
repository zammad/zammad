class Channel < ActiveRecord::Base
  def self.fetch
    Rails.application.config.channel.each { |channel|
      begin
        c = eval channel[:module] + '.new'
        c.fetch(channel)
      rescue Exception => e
        puts "can't use " + channel[:module]
        puts e.inspect
      end
    }
  end
end
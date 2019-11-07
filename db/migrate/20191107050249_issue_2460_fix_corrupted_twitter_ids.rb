class Issue2460FixCorruptedTwitterIds < ActiveRecord::Migration[5.2]
  def up
    return if !Setting.find_by(name: 'system_init_done')

    Channel.where(area: 'Twitter::Account').each do |channel|

      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = channel.options['auth']['consumer_key']
        config.consumer_secret     = channel.options['auth']['consumer_secret']
        config.access_token        = channel.options['auth']['oauth_token']
        config.access_token_secret = channel.options['auth']['oauth_token_secret']
      end

      channel.options['user']['id'] = client.user.id.to_s

      channel.save!
    end
  end
end

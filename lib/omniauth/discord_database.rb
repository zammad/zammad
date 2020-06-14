class DiscordDatabase < OmniAuth::Strategies::Discord
  option :name, 'discord'

  def initialize(app, *args, &block)

    # database lookup
    config  = Setting.get('auth_discord_credentials') || {}
    args[0] = config['client_id']
    args[1] = config['client_secret']
    super
  end

end
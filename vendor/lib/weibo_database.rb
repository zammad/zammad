class WeiboDatabase < OmniAuth::Strategies::Weibo
  option :name, 'weibo'

  def initialize(app, *args, &block)

    # database lookup
    config  = Setting.get('auth_weibo_credentials') || {}
    args[0] = config['client_id']
    args[1] = config['client_secret']
    super
  end

end

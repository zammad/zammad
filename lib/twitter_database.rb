module OmniAuth
  module Strategies

    class TwitterDatabase < OmniAuth::Strategies::Twitter
      option :name, 'twitter'

      def initialize(app, *args, &block)

        # database lookup
        puts 'TwitterDatabase -> initialize'
        config = Setting.get('auth_twitter_credentials') || {}
        args[0] = config['key'] 
        args[1] = config['secret'] 
        super
      end

    end

  end
end

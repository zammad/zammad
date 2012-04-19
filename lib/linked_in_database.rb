module OmniAuth
  module Strategies

    class LinkedInDatabase < OmniAuth::Strategies::LinkedIn
      option :name, 'linkedin'

      def initialize(app, *args, &block)

        # database lookup
        puts 'LinkedInDatabase -> initialize'
        config = Setting.get('auth_linkedin_credentials') || {}
        args[0] = config['app_id']
        args[1] = config['app_secret']
        super
      end

    end

  end
end

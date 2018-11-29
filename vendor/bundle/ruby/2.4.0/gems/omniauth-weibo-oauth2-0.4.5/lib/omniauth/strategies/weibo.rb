require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Weibo < OmniAuth::Strategies::OAuth2
      option :client_options, {
        :site           => "https://api.weibo.com",
        :authorize_url  => "/oauth2/authorize",
        :token_url      => "/oauth2/access_token",
        :token_method => :post
      }
      option :token_params, {
        :parse          => :json
      }

      uid do
        raw_info['id']
      end

      info do
        {
          :nickname     => raw_info['screen_name'],
          :name         => raw_info['name'],
          :location     => raw_info['location'],
          :image        => image_url,
          :description  => raw_info['description'],
          :urls => {
            'Blog'      => raw_info['url'],
            'Weibo'     => raw_info['domain'].empty? ? "http://weibo.com/u/#{raw_info['id']}" : "http://weibo.com/#{raw_info['domain']}",
          }
        }
      end

      extra do
        {
          :raw_info => raw_info
        }
      end

      def raw_info
        access_token.options[:mode] = :query
        access_token.options[:param_name] = 'access_token'
        @uid ||= access_token.get('/2/account/get_uid.json').parsed["uid"]
        @raw_info ||= access_token.get("/2/users/show.json", :params => {:uid => @uid}).parsed
      end

      def find_image
        raw_info[%w(avatar_hd avatar_large profile_image_url).find { |e| raw_info[e].present? }]
      end

      #url:                 option:   size:
      #avatar_hd            original  original_size
      #avatar_large         large     180x180
      #profile_image_url    middle    50x50
      #                     small     30x30
      #default is middle
      def image_url
        image_size = options[:image_size] || :middle
        case image_size.to_sym
        when :original
          url = raw_info['avatar_hd']
        when :large
          url = raw_info['avatar_large']
        when :small
          url = raw_info['avatar_large'].sub('/180/','/30/')
        else
          url = raw_info['profile_image_url']
        end
      end

      ##
      # You can pass +display+, +with_offical_account+ or +state+ params to the auth request, if
      # you need to set them dynamically. You can also set these options
      # in the OmniAuth config :authorize_params option.
      #
      # /auth/weibo?display=mobile&with_offical_account=1
      #
      def authorize_params
        super.tap do |params|
          %w[display with_offical_account forcelogin].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end
        end
      end

      protected
      def build_access_token
        params = {
          'client_id' => client.id,
          'client_secret' => client.secret,
          'code' => request.params['code'],
          'grant_type' => 'authorization_code',
          'redirect_uri' => options['redirect_uri']
        }.merge(token_params.to_hash(symbolize_keys: true))
        client.get_token(params, deep_symbolize(options.auth_token_params))
      end

    end
  end
end

OmniAuth.config.add_camelization "weibo", "Weibo"

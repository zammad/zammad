require "omniauth/strategies/oauth2"

module OmniAuth
  module Strategies
    class MicrosoftOffice365 < OmniAuth::Strategies::OAuth2
      option :name, :microsoft_office365

      DEFAULT_SCOPE="openid email profile https://outlook.office.com/contacts.read"

      option :client_options, {
        site:          "https://login.microsoftonline.com",
        authorize_url: "/common/oauth2/v2.0/authorize",
        token_url:     "/common/oauth2/v2.0/token"
      }

      option :authorize_options, [:scope]

      uid { raw_info["Id"] }

      info do
        {
          email:        raw_info["EmailAddress"],
          display_name: raw_info["DisplayName"],
          first_name:   first_last_from_display_name(raw_info["DisplayName"])[0],
          last_name:    first_last_from_display_name(raw_info["DisplayName"])[1],
          image:        avatar_file,
          alias:        raw_info["Alias"]
        }
      end

      extra do
        {
          "raw_info" => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get("https://outlook.office.com/api/v2.0/me/").parsed
      end

      def authorize_params
        super.tap do |params|
          %w[display scope auth_type].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end

          params[:scope] ||= DEFAULT_SCOPE
        end
      end

      private

      def first_last_from_display_name(display_name)
        # For display names with last name first like "Del Toro, Benicio"
        if last_first = display_name.match(/^([^,]+),\s+(\S+)$/)
          [last_first[2], last_first[1]]
        else
          display_name.split(/\s+/, 2)
        end
      end

      def callback_url
        options[:redirect_uri] || (full_host + script_name + callback_path)
      end

      def avatar_file
        photo = access_token.get("https://outlook.office.com/api/v2.0/me/photo/$value")
        ext   = photo.content_type.sub("image/", "") # "image/jpeg" => "jpeg"

        Tempfile.new(["avatar", ".#{ext}"]).tap do |file|
          file.binmode
          file.write(photo.body)
          file.rewind
        end

      rescue ::OAuth2::Error => e
        if e.response.status == 404 # User has no avatar...
          return nil
        elsif e.code['code'] == 'GetUserPhoto' && e.code['message'].match('not supported')
          nil
        else
          raise
        end
      end

    end
  end
end

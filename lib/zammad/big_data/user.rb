module Zammad
  module BigData
    class User < Zammad::BigData::Base

=begin

  file = Zammad::BigData::User.image('client@edenhofer.de')

returns

    {
      content: content,
      mime_type: mime_type,
    }

=end

      def self.image(email)

        # fetch logo
        response = UserAgent.post(
          "#{@@api_host}/api/v1/person/image",
          {
            email: email,
          },
          {
            open_timeout: @@open_timeout,
            read_timeout: @@read_timeout,
          },
        )
        if !response.success?
          Rails.logger.info "Can't fetch image for '#{email}' (maybe no avatar available), http code: #{response.code}"
          return
        end
        Rails.logger.info "Fetched image for '#{email}', http code: #{response.code}"
        mime_type = 'image/jpeg'
        {
          content: response.body,
          mime_type: mime_type,
        }
      end

    end
  end
end

module Zammad
  module BigData
    class Organization < Zammad::BigData::Base

=begin

  file = Zammad::BigData::Organization.image('edenhofer.de')

  file = Zammad::BigData::Organization.image('user@edenhofer.de') # will just use domain

returns

    {
      content: content,
      mime_type: mime_type,
    }

=end
      def self.image(domain)

        # strip, just use domain name
        domain = domain.sub(/^.+?@(.+?)$/, '\1')

        # fetch org logo
        response = UserAgent.post(
          "#{@@api_host}/api/v1/organization/image",
          {
            domain: domain
          },
          {
            open_timeout: @@open_timeout,
            read_timeout: @@read_timeout,
          },
        )
        if !response.success?
          Rails.logger.info "Can't fetch image for '#{domain}' (maybe no avatar available), http code: #{response.code}"
          return
        end
        Rails.logger.info "Fetched image for '#{domain}', http code: #{response.code}"
        mime_type = 'image/png'

        {
          content: response.body,
          mime_type: mime_type,
        }
      end

=begin

  result = Zammad::BigData::Organization.suggest_system_image('edenhofer.de')

returns

  true # or false

=end
      def self.suggest_system_image(domain)
        image = self.image(domain)
        return false if !image

        # store image 1:1
        product_logo = StaticAssets.store_raw( image[:content], image[:mime_type] )
        Setting.set('product_logo', product_logo)

        true
      end
    end
  end
end

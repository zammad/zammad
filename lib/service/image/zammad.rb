# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Service::Image::Zammad

  API_HOST      = 'https://images.zammad.com'.freeze
  OPEN_TIMEOUT  = 4
  READ_TIMEOUT  = 6
  TOTAL_TIMEOUT = 6

  def self.user(email)
    raise Exceptions::UnprocessableEntity, 'no email given' if email.blank?

    email.downcase!

    return if email.match?(%r{@example.com$})

    # fetch image
    response = UserAgent.post(
      "#{API_HOST}/api/v1/person/image",
      {
        email: email,
      },
      {
        open_timeout:  OPEN_TIMEOUT,
        read_timeout:  READ_TIMEOUT,
        total_timeout: TOTAL_TIMEOUT,
      },
    )
    if !response.success?
      Rails.logger.info "Can't fetch image for '#{email}' (maybe no avatar available), http code: #{response.code}"
      return
    end
    Rails.logger.info "Fetched image for '#{email}', http code: #{response.code}"
    mime_type = 'image/jpeg'
    {
      content:   response.body,
      mime_type: mime_type,
    }
  end

  def self.organization(domain)
    raise Exceptions::UnprocessableEntity, 'no domain given' if domain.blank?

    # strip, just use domain name
    domain = domain.sub(%r{^.+?@(.+?)$}, '\1')

    domain.downcase!
    return if domain == 'example.com'

    # fetch org logo
    response = UserAgent.post(
      "#{API_HOST}/api/v1/organization/image",
      {
        domain: domain
      },
      {
        open_timeout:  OPEN_TIMEOUT,
        read_timeout:  READ_TIMEOUT,
        total_timeout: TOTAL_TIMEOUT,
      },
    )
    if !response.success?
      Rails.logger.info "Can't fetch image for '#{domain}' (maybe no avatar available), http code: #{response.code}"
      return
    end
    Rails.logger.info "Fetched image for '#{domain}', http code: #{response.code}"
    mime_type = 'image/png'

    {
      content:   response.body,
      mime_type: mime_type,
    }
  end

  def self.organization_suggest(domain)
    image = organization(domain)
    return false if !image

    # store image 1:1
    product_logo = StaticAssets.store_raw(image[:content], image[:mime_type])
    Setting.set('product_logo', product_logo)

    true
  end
end

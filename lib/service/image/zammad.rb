# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Image::Zammad

  API_HOST      = 'https://images.zammad.com'.freeze
  OPEN_TIMEOUT  = 4
  READ_TIMEOUT  = 6
  TOTAL_TIMEOUT = 6
  DISABLE_IN_TEST_ENV = true

  def self.user(email)
    raise Exceptions::UnprocessableEntity, 'no email given' if email.blank?

    return if Rails.env.test? && DISABLE_IN_TEST_ENV

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
        verify_ssl:    true,
      },
    )
    if !response.success?
      Rails.logger.info "Can't fetch image for '#{email}' (maybe no avatar available), http code: #{response.code}"
      return
    end
    Rails.logger.info "Fetched image for '#{email}', http code: #{response.code}"
    {
      content:   response.body,
      mime_type: 'image/jpeg',
    }
  end

  def self.organization(domain)
    raise Exceptions::UnprocessableEntity, 'no domain given' if domain.blank?

    return if Rails.env.test? && DISABLE_IN_TEST_ENV

    # strip, just use domain name
    domain = domain.sub(%r{^.+?@(.+?)$}, '\1').downcase

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
        verify_ssl:    true,
      },
    )
    response_code = response.code
    if !response.success?
      Rails.logger.info "Can't fetch image for '#{domain}' (maybe no avatar available), http code: #{response_code}"
      return
    end
    Rails.logger.info "Fetched image for '#{domain}', http code: #{response_code}"

    {
      content:   response.body,
      mime_type: 'image/png',
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

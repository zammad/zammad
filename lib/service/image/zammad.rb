# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Service::Image::Zammad

  # rubocop:disable Style/ClassVars
  @@api_host = 'https://images.zammad.com'
  @@open_timeout = 4
  @@read_timeout = 6
  @@total_timeout = 6

  def self.user(email)
    raise Exceptions::UnprocessableEntity, 'no email given' if email.blank?

    email.downcase!

    return if email =~ /@example.com$/

    # fetch image
    response = UserAgent.post(
      "#{@@api_host}/api/v1/person/image",
      {
        email: email,
      },
      {
        open_timeout: @@open_timeout,
        read_timeout: @@read_timeout,
        total_timeout: @@total_timeout,
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

  def self.organization(domain)
    raise Exceptions::UnprocessableEntity, 'no domain given' if domain.blank?

    # strip, just use domain name
    domain = domain.sub(/^.+?@(.+?)$/, '\1')

    domain.downcase!
    return if domain == 'example.com'

    # fetch org logo
    response = UserAgent.post(
      "#{@@api_host}/api/v1/organization/image",
      {
        domain: domain
      },
      {
        open_timeout: @@open_timeout,
        read_timeout: @@read_timeout,
        total_timeout: @@total_timeout,
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

  def self.organization_suggest(domain)
    image = organization(domain)
    return false if !image

    # store image 1:1
    product_logo = StaticAssets.store_raw(image[:content], image[:mime_type])
    Setting.set('product_logo', product_logo)

    true
  end
end

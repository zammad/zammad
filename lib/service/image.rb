# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Service
  class Image
    include ApplicationLib

=begin

lookup user image based on email address

  file = Service::Image.user('skywalker@zammad.org')

returns

    {
      content: content,
      mime_type: mime_type,
    }

=end

    def self.user(address)

      # load backend
      backend = load_adapter_by_setting('image_backend')
      return if !backend

      backend.user(address)
    end

=begin

lookup organization image based on domain

  file = Service::Image.organization('edenhofer.de')

  file = Service::Image.organization('user@edenhofer.de') # will just use domain

returns

    {
      content: content,
      mime_type: mime_type,
    }

=end

    def self.organization(domain)

      # load backend
      backend = load_adapter_by_setting('image_backend')
      return if !backend

      backend.organization(domain)
    end

=begin

find organization image suggestion and store it as app logo

  result = Service::Image.organization_suggest('edenhofer.de')

returns

  true # or false

=end

    def self.organization_suggest(domain)

      # load backend
      backend = load_adapter_by_setting('image_backend')
      return if !backend

      result = backend.organization_suggest(domain)

      # sync logo to assets folder
      if result
        StaticAssets.sync
      end

      result
    end

  end
end

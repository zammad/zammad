# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# What a translation backend has to answer for the content translation services. A backend maps
# one translation service onto backend-neutral data; which one is used comes from the service config.
class Service::ContentTranslation::Backend::Base < Service::Base
  # Raises when the service behind this backend is not usable. Whether translation is switched on
  # at all is not its question - the content translation services ask that before.
  def self.ensure_enabled!
    nil
  end

  # Whether producing a translation takes long enough to answer the caller later.
  def self.background?
    false
  end

  # The stable name stored with every translation this backend produces.
  def self.backend_name
    raise NotImplementedError
  end

  # Keys the service config must carry for this backend, beside `provider`.
  def self.required_config_keys
    []
  end

  def backend_name
    self.class.backend_name
  end
end

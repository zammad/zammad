# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::PGP < SecureMailing::Backend
  MIN_REQUIRED_GPG_VERSION = '2.2.0'.freeze

  def self.active?
    Setting.get('pgp_integration') && required_version?
  end

  def self.required_version?
    SecureMailing::PGP::Tool.version >= Gem::Version.new(MIN_REQUIRED_GPG_VERSION)
  rescue Errno::ENOENT, Errno::EHWPOISON
    false
  end
end

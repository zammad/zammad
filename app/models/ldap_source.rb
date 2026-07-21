# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class LdapSource < ApplicationModel
  include CanSensitiveAssets
  include ChecksClientNotification
  include HasAuditLogs
  include CanPriorization

  SENSITIVE_FIELDS = %i[preferences.bind_pw].freeze

  default_scope { order(:prio, :id) }
  scope :active, -> { where(active: true) }

  store :preferences

  def self.by_user(user)
    return if user.blank? || user.source.blank?
    return if !%r{^Ldap::(\d+)$}.match?(user.source)

    LdapSource.find(user.source.split('::')[1])
  end
end

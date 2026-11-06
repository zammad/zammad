# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::HttpLog < Sequencer::Unit::Import::Common::Model::HttpLog
  uses :ldap_config

  private

  # The hourly sync would log every user again, so logging unchanged ones is opt-in
  #   per source for debugging. The statistics count them anyway.
  def log_unchanged?
    ActiveModel::Type::Boolean.new.cast(ldap_config&.dig(:log_unchanged)) || false
  end

  def url
    return "source #{LdapSource.find(ldap_config[:id]).name} (#{ldap_config[:id]}): #{action} -> #{remote_id}" if ldap_config.present? && ldap_config[:id].present?

    super
  end

  def facility
    'ldap'
  end
end

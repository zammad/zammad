# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::HttpLog < Sequencer::Unit::Import::Common::Model::HttpLog
  uses :ldap_config

  private

  def url
    return "source #{LdapSource.find(ldap_config[:id]).name} (#{ldap_config[:id]}): #{action} -> #{remote_id}" if ldap_config.present? && ldap_config[:id].present?

    super
  end

  def facility
    'ldap'
  end
end

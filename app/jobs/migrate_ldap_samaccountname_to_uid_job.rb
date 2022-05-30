# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class MigrateLdapSamaccountnameToUidJob < ApplicationJob
  def perform
    LdapSource.find_each do |ldap_config|
      MigrateLdapSamaccountnameToUidJob::Ldap.new(ldap_config).perform
    end
  end
end

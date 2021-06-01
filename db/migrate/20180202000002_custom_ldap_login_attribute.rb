# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CustomLdapLoginAttribute < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')
    return if no_change_needed?

    perform_changes
  end

  private

  def perform_changes
    delete_spared
    update_config
  end

  def delete_spared
    # remove samaccountname which is always wrong if there is more than
    # one other login attribute since it's automatically added
    ldap_config[:user_attributes].delete('samaccountname')

    # this should not happen but remove any other duplicate that
    # maps to login and keep the "first" in the list
    # - which is more or less random
    login_attributes.reject { |e| e == 'samaccountname' }.drop(1).each do |spared|
      ldap_config[:user_attributes].delete(spared)
    end
  end

  def update_config
    Import::Ldap.config = ldap_config
  end

  def login_attributes
    @login_attributes ||= ldap_config[:user_attributes].select { |_local, remote| remote == 'login' }.keys
  end

  def no_change_needed?
    return true if ldap_config.blank?
    return true if ldap_config[:user_attributes].blank?

    ldap_config[:user_attributes].values.count('login') < 2
  end

  def ldap_config
    @ldap_config ||= Import::Ldap.config
  end
end

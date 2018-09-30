class Issue2140ResetLdapConfig < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    ldap_config = Setting.get('ldap_config')

    # finish if LDAP config isn't broken
    ldap_config.to_json
  rescue Encoding::UndefinedConversionError
    ldap_config[:wizardData].delete(:backend_user_attributes)

    Setting.set('ldap_config', ldap_config)
  end
end

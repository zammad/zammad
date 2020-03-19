class Controllers::Integration::LdapControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.integration.ldap')
end

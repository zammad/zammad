# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue4943SsoRoleMapping < ActiveRecord::Migration[8.1]
  ROLE_ATTRIBUTE_FIELDS = {
    'saml'           => {
      display:     'Role attribute',
      placeholder: 'http://schemas.xmlsoap.org/claims/Group',
      help:        'Name of the SAML attribute whose values are mapped to roles. Leave empty to manage roles in Zammad.',
    },
    'openid_connect' => {
      display:     'Role claim',
      placeholder: 'resource_access.zammad.roles',
      help:        'Name of the claim in the ID token or userinfo whose values are mapped to roles, e.g. the client roles of the identity provider. Use dots for nested claims. Leave empty to manage roles in Zammad.',
    },
  }.freeze

  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ROLE_ATTRIBUTE_FIELDS.each do |provider, role_attribute_field|
      setting = Setting.find_by(name: "auth_#{provider}_credentials")
      next if !setting

      add_form_fields(setting, role_attribute_field)
      add_validation(setting)
      setting.save!
    end
  end

  private

  def add_form_fields(setting, role_attribute_field)
    form = setting.options[:form]
    return if form.blank? || form.any? { |field| field[:name] == 'role_mapping::attribute' }

    form.push(
      role_attribute_field.merge(null: true, name: 'role_mapping::attribute', tag: 'input'),
      {
        display:          'Role mapping',
        null:             true,
        name:             'role_mapping::map',
        tag:              'key_relation_map',
        relation:         'Role',
        key_display:      'Value',
        key_placeholder:  'agent',
        relation_display: 'Roles',
        help:             'Each value is a single value of the claim or attribute. Users get the roles of all matching values. Their roles are replaced on every login, except for users whose roles are managed by LDAP.',
      },
      {
        display:   'If no role is mapped',
        null:      true,
        name:      'role_mapping::unmatched',
        tag:       'select',
        options:   {
          'signup_roles' => 'Assign signup roles',
          'deny'         => 'Deny login',
        },
        default:   'signup_roles',
        translate: true,
      },
    )
  end

  def add_validation(setting)
    validations = Array.wrap(setting.preferences[:validations])
    return if validations.include?('Setting::Validation::AuthRoleMapping')

    setting.preferences[:validations] = validations + ['Setting::Validation::AuthRoleMapping']
  end
end

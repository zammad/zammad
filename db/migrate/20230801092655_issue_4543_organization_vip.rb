# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Issue4543OrganizationVip < ActiveRecord::Migration[6.1]
  RESERVED_NAME  = 'vip'.freeze
  SANITIZED_NAME = '_vip'.freeze
  VIP_ATTRIBUTE_PAYLOAD = {
    name:        'vip',
    display:     'VIP',
    data_type:   'boolean',
    data_option: {
      null:       true,
      default:    false,
      item_class: 'formGroup--halfSize',
      options:    {
        false => 'no',
        true  => 'yes',
      },
      translate:  true,
      permission: ['admin.organization'],
    },
    editable:    false,
    active:      true,
    screens:     {
      edit:   {
        '-all-' => {
          null: true,
        },
      },
      create: {
        '-all-' => {
          null: true,
        },
      },
      view:   {
        '-all-' => {
          shown: false,
        },
      },
    },
    position:    1450,
  }.freeze

  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # If there is already a boolean 'vip' attribute, we reuse it,
    #   but switch it to the new values.
    return if update_custom_vip_boolean_attribute

    # If there is a 'vip' attribute of another type, we rename it
    #   to '_vip' and create the new internal attribute thereafter.
    rename_custom_vip_attribute
    create_vip_db_column
    create_vip_attribute
  end

  private

  def custom_vip_attribute
    ObjectManager::Attribute.get(object: 'Organization', name: RESERVED_NAME.dup)
  end

  def update_custom_vip_boolean_attribute
    return false if !custom_vip_attribute || custom_vip_attribute.data_type != 'boolean'

    custom_vip_attribute.update!(**VIP_ATTRIBUTE_PAYLOAD)
    true
  end

  def rename_custom_vip_attribute
    return if !custom_vip_attribute

    custom_vip_attribute.update!(name: SANITIZED_NAME)

    return if ActiveRecord::Base.connection.columns('organizations').map(&:name).exclude?(RESERVED_NAME)

    ActiveRecord::Migration.rename_column(:organizations, RESERVED_NAME.to_sym, SANITIZED_NAME.to_sym)
    Organization.connection.schema_cache.clear!
    Organization.reset_column_information
  end

  def create_vip_db_column
    change_table :organizations do |t|
      t.boolean :vip, default: false, null: false
    end

    Organization.reset_column_information
  end

  def create_vip_attribute
    UserInfo.current_user_id = 1

    ObjectManager::Attribute.add(
      **VIP_ATTRIBUTE_PAYLOAD,
      force:      true,
      object:     'Organization',
      to_create:  false,
      to_migrate: false,
      to_delete:  false,
    )
  end
end

class UpdateSettingPostmasterFilter2 < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '0012_postmaster_filter_sender_is_system_address',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter to check if email got created via email as Zammad.',
      options: {},
      state: 'Channel::Filter::SenderIsSystemAddress',
      frontend: false
    )
    ObjectManager::Attribute.add(
      force: true,
      object: 'Ticket',
      name: 'customer_id',
      display: 'Customer',
      data_type: 'user_autocompletion',
      data_option: {
        relation: 'User',
        autocapitalize: false,
        multiple: false,
        guess: true,
        null: false,
        limit: 200,
        placeholder: 'Enter Person or Organization/Company',
        minLengt: 2,
        translate: false,
      },
      editable: false,
      active: true,
      screens: {
        create_top: {
          Agent: {
            null: false,
          },
        },
        edit: {},
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 10,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end

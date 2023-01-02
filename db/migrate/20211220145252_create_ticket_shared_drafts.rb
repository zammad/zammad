# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CreateTicketSharedDrafts < ActiveRecord::Migration[5.0]
  def change # rubocop:disable Metrics/AbcSize
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :ticket_shared_draft_zooms do |t|
      t.references :ticket, null: false, foreign_key: { to_table: :tickets }
      t.text       :new_article
      t.text       :ticket_attributes

      t.column :created_by_id, :integer, null: true
      t.column :updated_by_id, :integer, null: true

      t.timestamps limit: 3
    end

    create_table :ticket_shared_draft_starts do |t|
      t.references :group, null: false, foreign_key: { to_table: :groups }
      t.string     :name
      t.text       :content

      t.column :created_by_id, :integer, null: true
      t.column :updated_by_id, :integer, null: true

      t.timestamps limit: 3
    end

    change_table :groups do |t|
      t.boolean :shared_drafts, null: false, default: true
    end

    Group.reset_column_information

    UserInfo.current_user_id = 1
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Group',
      name:        'shared_drafts',
      display:     'Shared Drafts',
      data_type:   'active',
      data_option: {
        null:       false,
        default:    true,
        permission: ['admin.group'],
      },
      editable:    true,
      active:      true,
      screens:     {
        create: {
          '-all-' => {
            null: false,
          },
        },
        edit:   {
          '-all-': {
            null: false,
          },
        },
        view:   {
          '-all-' => {
            shown: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1400,
    )
  end
end

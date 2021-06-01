# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Using older 5.0 migration to stick to Integer primary keys. Otherwise migration fails in MySQL.
class InitializeKnowledgeBase < ActiveRecord::Migration[5.0]
  def change
    return if ActiveRecord::Base.connection.table_exists? 'knowledge_bases'

    create_table :knowledge_bases do |t|
      t.string :iconset, limit: 30, null: false

      t.string :color_highlight, limit: 25, null: false
      t.string :color_header,    limit: 25, null: false

      t.string :homepage_layout, null: false
      t.string :category_layout, null: false

      t.boolean :active, null: false, default: true

      t.string :custom_address

      t.timestamps null: false # rubocop:disable Zammad/ExistsDateTimePrecision
    end

    create_table :knowledge_base_locales do |t|
      t.belongs_to :knowledge_base, null: false, foreign_key: { to_table: :knowledge_bases }
      t.belongs_to :system_locale,  null: false, foreign_key: { to_table: :locales }
      t.boolean    :primary, null: false, default: false

      t.timestamps null: false # rubocop:disable Zammad/ExistsDateTimePrecision
    end
    add_index :knowledge_base_locales, %i[system_locale_id knowledge_base_id], name: 'index_kb_locale_on_kb_system_locale_kb', unique: true

    create_table :knowledge_base_translations do |t|
      t.string :title, limit: 250, null: false
      t.string :footer_note,       null: false

      t.references :kb_locale,      null: false, foreign_key: { to_table: :knowledge_base_locales }
      t.references :knowledge_base, null: false, foreign_key: { to_table: :knowledge_bases, on_delete: :cascade }

      t.timestamps null: false # rubocop:disable Zammad/ExistsDateTimePrecision
    end
    add_index :knowledge_base_translations, %i[kb_locale_id knowledge_base_id], name: 'index_kb_t_on_kb_locale_kb', unique: true

    create_table :knowledge_base_categories do |t|
      t.references :knowledge_base, null: false, foreign_key: { to_table: :knowledge_bases }
      t.references :parent,         null: true,  foreign_key: { to_table: :knowledge_base_categories }

      t.string  :category_icon, null: false, limit: 30
      t.integer :position,      null: false, index: true

      t.timestamps null: false # rubocop:disable Zammad/ExistsDateTimePrecision
    end

    create_table :knowledge_base_category_translations do |t|
      t.string :title, limit: 250, null: false

      t.references :kb_locale, null: false, foreign_key: { to_table: :knowledge_base_locales }
      t.references :category,  null: false, foreign_key: { to_table: :knowledge_base_categories, on_delete: :cascade }

      t.timestamps null: false # rubocop:disable Zammad/ExistsDateTimePrecision
    end
    add_index :knowledge_base_category_translations, %i[kb_locale_id category_id], name: 'index_kb_c_t_on_kb_locale_category', unique: true

    create_table :knowledge_base_answers do |t|
      t.references :category, null: false, foreign_key: { to_table: :knowledge_base_categories }

      t.boolean :promoted,      null: false, default: false
      t.text    :internal_note, null: true,  limit: 1.megabyte
      t.integer :position,      null: false, index: true

      t.timestamp  :archived_at,  limit: 3, null: true
      t.references :archived_by,  foreign_key: { to_table: :users }
      t.timestamp  :internal_at,  limit: 3, null: true
      t.references :internal_by,  foreign_key: { to_table: :users }
      t.timestamp  :published_at, limit: 3, null: true
      t.references :published_by, foreign_key: { to_table: :users }

      t.timestamps null: false # rubocop:disable Zammad/ExistsDateTimePrecision
    end

    create_table :knowledge_base_answer_translation_contents do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.text :body, null: true, limit: 20.megabytes + 1
    end

    create_table :knowledge_base_answer_translations do |t|
      t.string :title, limit: 250, null: false

      t.references :kb_locale, null: false, foreign_key: { to_table: :knowledge_base_locales }
      t.references :answer,    null: false, foreign_key: { to_table: :knowledge_base_answers, on_delete: :cascade }
      t.references :content,   null: false, foreign_key: { to_table: :knowledge_base_answer_translation_contents }

      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }

      t.timestamps null: false # rubocop:disable Zammad/ExistsDateTimePrecision
    end
    add_index :knowledge_base_answer_translations, %i[kb_locale_id answer_id], name: 'index_kb_a_t_on_kb_locale_answer', unique: true

    create_table :knowledge_base_menu_items do |t|
      t.references :kb_locale, null: false, foreign_key: { to_table: :knowledge_base_locales, on_delete: :cascade }
      t.string     :location,  null: false, index: true
      t.integer    :position,  null: false, index: true
      t.string     :title,     null: false, limit: 100
      t.string     :url,       null: false, limit: 500
      t.boolean    :new_tab,   null: false, default: false

      t.timestamps # rubocop:disable Zammad/ExistsDateTimePrecision
    end

    Setting.create_if_not_exists(
      title:       'Kb multi-lingual support',
      name:        'kb_multi_lingual_support',
      area:        'Kb::Core',
      description: 'Support of multi-lingual Knowledge Base.',
      options:     {},
      state:       true,
      preferences: { online_service_disable: true },
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'Kb active',
      name:        'kb_active',
      area:        'Kb::Core',
      description: 'Defines if KB navbar button is enabled. Updated in KnowledgeBase callback.',
      state:       false,
      preferences: {
        prio:           1,
        trigger:        ['menu:render'],
        authentication: true,
        permission:     ['admin.knowledge_base'],
      },
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'Kb active publicly',
      name:        'kb_active_publicly',
      area:        'Kb::Core',
      description: 'Defines if KB navbar button is enabled for users without KB permission. Updated in CanBePublished callback.',
      state:       false,
      preferences: {
        prio:           1,
        trigger:        ['menu:render'],
        authentication: true,
        permission:     [],
      },
      frontend:    true
    )

    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.knowledge_base',
      note:        'Create and setup %s',
      preferences: {
        translations: ['Knowledge Base']
      }
    )

    Permission.create_if_not_exists(
      name:        'knowledge_base',
      note:        'Manage %s',
      preferences: {
        translations: ['Knowledge Base'],
        disabled:     true,
      }
    )

    Permission.create_if_not_exists(
      name:        'knowledge_base.reader',
      note:        'Access %s',
      preferences: {
        translations: ['Knowledge Base']
      }
    )

    Permission.create_if_not_exists(
      name:        'knowledge_base.editor',
      note:        'Manage %s',
      preferences: {
        translations: ['Knowledge Base Editor']
      }
    )

    Role.with_permissions(['admin']).each do |role|
      role.permission_grant('knowledge_base.editor')
    end

    Role.with_permissions(['ticket.agent']).each do |role|
      role.permission_grant('knowledge_base.reader')
    end
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RenameLocaleOnUsers, type: :db_migration do
  context 'when custom OMA attribute #locale exists', db_strategy: :reset do
    before do
      ObjectManager::Attribute.add(
        force:         true,
        object:        'User',
        name:          'locale',
        display:       'Locale',
        data_type:     'select',
        data_option:   {
          'default' => '',
          'options' => {},
        },
        active:        true,
        position:      20,
        to_migrate:    true,
        created_by_id: 1,
        updated_by_id: 1,
      )

      ObjectManager::Attribute.migration_execute
    end

    it 'renames #locale' do
      expect { migrate }
        .to change { ActiveRecord::Base.connection.columns('users').map(&:name) }
        .to not_include('locale')
        .and include('_locale')

      expect(ObjectManager::Attribute.exists?(name: 'locale')).to be(false)
      expect(ObjectManager::Attribute.exists?(name: '_locale')).to be(true)
    end
  end

  context 'when no #locale attribute exists' do
    it 'makes no changes to the "users" table' do
      expect { migrate }
        .not_to change { ActiveRecord::Base.connection.columns('users') }
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5409WrongDbColumnArrayType, type: :db_migration do
  describe 'with PostgreSQL backend', db_adapter: :postgresql, db_strategy: :reset do
    before do
      change_column :smime_certificates, :email_addresses, :text, null: true, array: true
      change_column :pgp_keys, :email_addresses, :text, null: true, array: true
      change_column :public_links, :screen, :text, null: false, array: true

      SMIMECertificate.reset_column_information
      PGPKey.reset_column_information
      PublicLink.reset_column_information
    end

    it 'migrates column array type' do
      expect { migrate }
        .to change { SMIMECertificate.columns.find { |c| c.name == 'email_addresses' }.type }.from(:text).to(:string)
        .and change { PGPKey.columns.find { |c| c.name == 'email_addresses' }.type }.from(:text).to(:string)
        .and change { PublicLink.columns.find { |c| c.name == 'screen' }.type }.from(:text).to(:string)
    end

    context 'with multiselect and multi_tree_select object attributes' do
      let(:screens)              { { create_middle: { '-all-' => { shown: true, required: false } } } }
      let(:no_migration_execute) { false }

      before do
        create(:object_manager_attribute_multiselect, object_name: object.to_s, name: 'multi_select', display: 'Multi Select', screens: screens, additional_data_options: { options: { '1' => 'Option 1', '2' => 'Option 2', '3' => 'Option 3' } })
        create(:object_manager_attribute_multi_tree_select, object_name: object.to_s, name: 'multi_tree_select', display: 'Multi Tree Select', screens: screens, additional_data_options: { options: [ { name: 'Parent 1', value: '1', children: [ { name: 'Option A', value: '1::a' }, { name: 'Option B', value: '1::b' } ] }, { name: 'Parent 2', value: '2', children: [ { name: 'Option C', value: '2::c' } ] }, { name: 'Option 3', value: '3' } ], default: '', null: true, relation: '', maxlength: 255, nulloption: true })

        next if no_migration_execute

        ObjectManager::Attribute.migration_execute

        change_column object.table_name.to_sym, :multi_select, :text, null: true, array: true
        change_column object.table_name.to_sym, :multi_tree_select, :text, null: true, array: true

        object.reset_column_information
      end

      shared_examples 'migrating column array type' do
        it 'migrates column array type' do
          expect { migrate }
            .to change { object.columns.find { |c| c.name == 'multi_select' }.type }.from(:text).to(:string)
            .and change { object.columns.find { |c| c.name == 'multi_tree_select' }.type }.from(:text).to(:string)
        end
      end

      context 'with ticket object' do
        let(:object) { Ticket }

        it_behaves_like 'migrating column array type'
      end

      context 'with user object' do
        let(:object) { User }

        it_behaves_like 'migrating column array type'
      end

      context 'with organization object' do
        let(:object) { Organization }

        it_behaves_like 'migrating column array type'
      end

      context 'with groups object' do
        let(:object) { Group }

        it_behaves_like 'migrating column array type'
      end

      context 'without executing table column migration' do
        let(:object)               { Ticket }
        let(:no_migration_execute) { true }

        it 'does not throw errors (#5430)' do
          expect { migrate }.not_to raise_error
        end
      end
    end
  end

  describe 'with MariaDB backend', db_adapter: :mysql do
    it 'does not migrate column array type' do
      expect { migrate }
        .to not_change { SMIMECertificate.columns.find { |c| c.name == 'email_addresses' }.type }.from(:json)
        .and not_change { PGPKey.columns.find { |c| c.name == 'email_addresses' }.type }.from(:json)
        .and not_change { PublicLink.columns.find { |c| c.name == 'screen' }.type }.from(:json)
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tasks::Zammad::DB::Pgloader do
  describe 'Task handler', db_adapter: :mysql, db_strategy: :reset_all do
    let(:command_file) do
      <<~PGLOADER
        LOAD DATABASE
          FROM #{mysql_url}

          -- Adjust the PostgreSQL URL below to correct value before executing this command file.
          INTO pgsql://zammad:pgsql_password@localhost/zammad

        ALTER SCHEMA '#{config['database']}' RENAME TO 'public'

        #{command_file_after}
        WITH BATCH CONCURRENCY = 1
        SET timezone = 'UTC'
        SET client_timezone TO '00:00'
        ;
      PGLOADER
    end

    shared_examples 'preparing pgloader command file' do
      it 'prepares pgloader command file' do
        expect(described_class.command_file).to eq(command_file)
      end
    end

    context 'with mysql adapter' do
      let(:config)    { Rails.configuration.database_configuration[Rails.env] }
      let(:mysql_url) { mysql_url_from_config(config) }

      context 'with empty database' do
        let(:command_file_after) do
          <<~PGLOADER
            AFTER LOAD DO
              $$ alter table public_links alter column screen type text[] using translate(screen::text, '[]', '{}')::text[] $$
          PGLOADER
        end

        it_behaves_like 'preparing pgloader command file'
      end

      context 'with multiselect and multi_tree_select object attributes' do
        let(:command_file_after) do
          <<~PGLOADER
            AFTER LOAD DO
              $$ alter table public_links alter column screen type text[] using translate(screen::text, '[]', '{}')::text[] $$,
              $$ alter table #{object.table_name} alter column multi_select type text[] using translate(multi_select::text, '[]', '{}')::text[] $$,
              $$ alter table #{object.table_name} alter column multi_tree_select type text[] using translate(multi_tree_select::text, '[]', '{}')::text[] $$
          PGLOADER
        end

        before do
          screens = { create_middle: { '-all-' => { shown: true, required: false } } }
          create(:object_manager_attribute_multiselect, object_name: object.to_s, name: 'multi_select', display: 'Multi Select', screens: screens, additional_data_options: { options: { '1' => 'Option 1', '2' => 'Option 2', '3' => 'Option 3' } })
          create(:object_manager_attribute_multi_tree_select, object_name: object.to_s, name: 'multi_tree_select', display: 'Multi Tree Select', screens: screens, additional_data_options: { options: [ { name: 'Parent 1', value: '1', children: [ { name: 'Option A', value: '1::a' }, { name: 'Option B', value: '1::b' } ] }, { name: 'Parent 2', value: '2', children: [ { name: 'Option C', value: '2::c' } ] }, { name: 'Option 3', value: '3' } ], default: '', null: true, relation: '', maxlength: 255, nulloption: true })
        end

        context 'with ticket object' do
          let(:object) { Ticket }

          it_behaves_like 'preparing pgloader command file'
        end

        context 'with user object' do
          let(:object) { User }

          it_behaves_like 'preparing pgloader command file'
        end

        context 'with organization object' do
          let(:object) { Organization }

          it_behaves_like 'preparing pgloader command file'
        end

        context 'with groups object' do
          let(:object) { Group }

          it_behaves_like 'preparing pgloader command file'
        end
      end
    end

    context 'without mysql adapter' do
      before do
        ENV['ZAMMAD_TEST_DATABASE_CONFIG'] = JSON.generate({
                                                             adapter: 'postgresql'
                                                           })
      end

      it 'raises an error' do
        expect { described_class.task_handler }.to raise_error('Incorrect database configuration, expected `mysql2` for adapter but got `postgresql`, check your database.yml!')
      end
    end

    # Generate URL of the source MySQL server:
    #   mysql://[mysql_username[:mysql_password]@][mysql_host[:mysql_port]/][mysql_database]
    def mysql_url_from_config(config)
      url = 'mysql://'

      username = config['username']
      password = config['password']
      host     = config['host']
      port     = config['port']
      database = config['database']

      if username.present?
        url += username

        if password.present?
          url += ":#{password}"
        end

        url += '@'
      end

      if host.present?
        url += host

        if port.present?
          url += ":#{port}"
        end

        url += '/'
      end

      if database.present?
        url += database
      end

      url
    end
  end

  describe 'MySQL URL generation' do
    context 'with all attributes' do
      before do
        ENV['ZAMMAD_TEST_DATABASE_CONFIG'] = JSON.generate({
                                                             adapter:  'mysql',
                                                             username: 'mysql_user',
                                                             password: 'mysql_pass',
                                                             host:     'mysql_host',
                                                             port:     '3306',
                                                             database: 'mysql_database',
                                                           })
      end

      it 'returns full url' do
        expect(described_class.mysql_url).to eq('mysql://mysql_user:mysql_pass@mysql_host:3306/mysql_database')
      end
    end

    context 'without credentials' do
      context 'without password' do
        before do
          ENV['ZAMMAD_TEST_DATABASE_CONFIG'] = JSON.generate({
                                                               adapter:  'mysql',
                                                               username: 'mysql_user',
                                                               host:     'mysql_host',
                                                               port:     '3306',
                                                               database: 'mysql_database',
                                                             })
        end

        it 'returns url without password' do
          expect(described_class.mysql_url).to eq('mysql://mysql_user@mysql_host:3306/mysql_database')
        end
      end

      context 'without username' do
        before do
          ENV['ZAMMAD_TEST_DATABASE_CONFIG'] = JSON.generate({
                                                               adapter:  'mysql',
                                                               password: 'mysql_password',
                                                               host:     'mysql_host',
                                                               port:     '3306',
                                                               database: 'mysql_database',
                                                             })
        end

        it 'returns url without credentials' do
          expect(described_class.mysql_url).to eq('mysql://mysql_host:3306/mysql_database')
        end
      end
    end

    context 'without hostname' do
      context 'without port' do
        before do
          ENV['ZAMMAD_TEST_DATABASE_CONFIG'] = JSON.generate({
                                                               adapter:  'mysql',
                                                               host:     'mysql_host',
                                                               database: 'mysql_database',
                                                             })
        end

        it 'returns url without port' do
          expect(described_class.mysql_url).to eq('mysql://mysql_host/mysql_database')
        end
      end

      context 'without host' do
        before do
          ENV['ZAMMAD_TEST_DATABASE_CONFIG'] = JSON.generate({
                                                               adapter:  'mysql',
                                                               port:     '3306',
                                                               database: 'mysql_database',
                                                             })
        end

        it 'returns url without hostname' do
          expect(described_class.mysql_url).to eq('mysql://localhost:3306/mysql_database')
        end
      end
    end

    context 'without path' do
      context 'without database' do
        before do
          ENV['ZAMMAD_TEST_DATABASE_CONFIG'] = JSON.generate({
                                                               adapter: 'mysql',
                                                               host:    'mysql_host',
                                                             })
        end

        it 'returns url without path' do
          expect(described_class.mysql_url).to eq('mysql://mysql_host/')
        end
      end
    end
  end
end

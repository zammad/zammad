# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Rails 5.0 has changed to only store and read ActiveSupport::HashWithIndifferentAccess from stores
# we extended lib/core_ext/active_record/store/indifferent_coder.rb to read also ActionController::Parameters
# and convert them to ActiveSupport::HashWithIndifferentAccess for migration in db/migrate/20171023000001_fixed_store_upgrade_ror_45.rb.
RSpec.describe FixedStoreUpgradeRor45, type: :db_migration do
  subject(:taskbar) { Taskbar.last }

  context 'when DB contains `store`d attributes saved as unpermitted ActionController::Parameters' do
    before do
      ActiveRecord::Base.connection.execute(<<~SQL.tap { |sql| sql.delete!('`') if !mysql? }) # rubocop:disable Rails/SquishedSQLHeredocs
        INSERT INTO taskbars (`user_id`, `client_id`, `key`, `callback`, `state`, `params`, `prio`, `notify`, `active`, `preferences`, `last_contact`, `updated_at`, `created_at`)
        VALUES (#{user.id},
                '123',
                'Ticket-123',
                'TicketZoom',
                '#{state.to_yaml}',
                '#{params.to_yaml}',
                1,
                FALSE,
                TRUE,
                '#{preferences.to_yaml}',
                '#{last_contact}',
                '#{last_contact}',
                '#{last_contact}')
      SQL
    end

    let(:mysql?)       { ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2' }
    let(:user)         { User.last }
    let(:last_contact) { '2017-09-01 10:10:00' }
    let(:state)        { ActionController::Parameters.new('ticket' => {}, 'article' => {}) }
    let(:params)       { ActionController::Parameters.new('ticket_id' => 1234, 'shown' => true) }
    let(:preferences) do
      ActionController::Parameters.new(
        'tasks' => [
          {
            'id'           => 99_282,
            'user_id'      => 85_370,
            'last_contact' => 1.week.after(Time.zone.parse(last_contact)),
            'changed'      => true
          }
        ]
      )
    end

    it 'converts `store`d attributes to ActiveSupport::HashWithIndifferentAccess, preserving original values' do
      expect { migrate }
        .to change { taskbar.reload.read_attribute_before_type_cast(:state) }
        .and not_change { taskbar.reload.state }
        .and change { taskbar.reload.read_attribute_before_type_cast(:params) }
        .and not_change { taskbar.reload.params }
        .and change { taskbar.reload.read_attribute_before_type_cast(:preferences) }

      expect(taskbar.attributes.slice('params', 'preferences', 'state').values)
        .to all(be_a(ActiveSupport::HashWithIndifferentAccess))
    end
  end
end

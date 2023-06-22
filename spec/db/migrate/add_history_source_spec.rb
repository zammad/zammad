# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddHistorySource, db_strategy: :reset, type: :db_migration do
  before do
    ActiveRecord::Migration.remove_column :histories, :sourceable_id
    ActiveRecord::Migration.remove_column :histories, :sourceable_type
    ActiveRecord::Migration.remove_column :histories, :sourceable_name
    History.reset_column_information
  end

  describe 'migrate SQL table' do
    it 'does add the column' do
      migrate
      expect(History.column_names).to include('sourceable_id', 'sourceable_type', 'sourceable_name')
    end
  end

  describe 'migrate time_trigger_performed history entries' do
    let(:trigger) { create(:trigger) }
    let(:history_entry) do
      create(:history,
             history_type:           'time_trigger_performed',
             value_from:             'reminder_reached',
             value_to:               trigger.name,
             related_history_object: trigger)
    end

    let(:initial_attributes) { history_entry.attributes }
    let(:converted_old_attributes) do
      history_entry.attributes.merge(
        'sourceable_type'           => 'Trigger',
        'sourceable_id'             => trigger.id,
        'sourceable_name'           => trigger.name,
        'related_history_object_id' => nil,
        'related_o_id'              => nil,
        'value_to'                  => nil
      )
    end

    it 'migrates the entry' do
      expect { migrate }
        .to change { history_entry.reload.attributes }
        .from(initial_attributes)
        .to(converted_old_attributes)
    end
  end
end

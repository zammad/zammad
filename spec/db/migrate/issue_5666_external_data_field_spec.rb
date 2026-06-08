# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5666ExternalDataField, db_strategy: :reset, type: :db_migration do
  let(:attribute) { create(:object_manager_attribute_autocompletion_ajax_external_data_source) }
  let(:ticket)    { create(:ticket) }

  it 'ensures pre-existing objects get correct value' do
    ticket

    add_old_style_field

    expect { migrate }
      .to change { ticket.reload.attributes[attribute.name] }
      .to({})
  end

  def add_old_style_field
    # Add a field manually with the old confioguration
    ActiveRecord::Migration.add_column(
      'tickets',
      attribute.name,
      :jsonb,
      null: true,
    )

    Ticket.reset_column_information
  end
end

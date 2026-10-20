# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManagerAttributeAndCoreWorkflowJsonColumns, db_strategy: :reset, type: :db_migration do
  let(:attribute)         { ObjectManager::Attribute.find_by(name: 'state_id', object_lookup_id: ObjectLookup.by_name('Ticket')) }
  let(:boolean_attribute) { create(:object_manager_attribute_boolean) }
  let(:select_attribute)  { create(:object_manager_attribute_select) }
  let(:sorted_attribute)  { create(:object_manager_attribute_select) }
  let(:workflow)          { create(:core_workflow, perform: { 'ticket.priority_id' => { 'operator' => 'show', 'show' => true } }) }

  let(:attribute_data_option) { attribute.data_option.to_h }
  let(:attribute_screens)     { attribute.screens.to_h }
  let(:workflow_perform)      { workflow.perform.to_h }

  # the store coder kept the boolean and integer option keys as YAML booleans and integers
  let(:boolean_data_option) { { 'default' => true, 'null' => true, 'options' => { true => 'yes', false => 'no' } } }
  let(:select_data_option)  { { 'default' => 1, 'null' => true, 'options' => { 1 => 'one', 2 => 'two' } } }

  # hash options created via API with customsort on, shown in stored order by the legacy UI
  let(:sorted_data_option) { { 'default' => '', 'null' => true, 'customsort' => 'on', 'options' => { 'zz' => 'Last', 'a' => 'First' } } }

  before do
    attribute_data_option
    attribute_screens
    workflow_perform

    # recreate the state before the migration: text columns holding the YAML of the store coder
    text_columns('object_manager_attributes', %w[screens data_option data_option_new])
    text_columns('core_workflows', %w[preferences condition_saved condition_selected perform])

    write_yaml('object_manager_attributes', attribute.id, 'screens' => attribute_screens, 'data_option' => attribute_data_option, 'data_option_new' => nil)
    write_yaml('object_manager_attributes', boolean_attribute.id, 'screens' => boolean_attribute.screens.to_h, 'data_option' => boolean_data_option, 'data_option_new' => nil)
    write_yaml('object_manager_attributes', select_attribute.id, 'screens' => select_attribute.screens.to_h, 'data_option' => select_data_option, 'data_option_new' => nil)
    write_yaml('object_manager_attributes', sorted_attribute.id, 'screens' => sorted_attribute.screens.to_h, 'data_option' => sorted_data_option, 'data_option_new' => nil)
    write_yaml('core_workflows', workflow.id, 'preferences' => workflow.preferences.to_h, 'condition_saved' => workflow.condition_saved.to_h, 'condition_selected' => workflow.condition_selected.to_h, 'perform' => workflow_perform)
  end

  def text_columns(table, columns)
    columns.each do |column|
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Base.connection.change_column table, column, :text, null: true, default: nil
      end
    end
  end

  def write_yaml(table, id, values)
    connection  = ActiveRecord::Base.connection
    assignments = values.map { |column, value| "#{column} = #{connection.quote(value&.to_yaml)}" }.join(', ')

    connection.update("UPDATE #{table} SET #{assignments} WHERE id = #{id}")
  end

  def column_type(table, column)
    ActiveRecord::Base.connection.columns(table).detect { |row| row.name == column }.type
  end

  it 'saves records while the columns still hold YAML', :aggregate_failures, system_init_done: true do
    yaml_attribute = ObjectManager::Attribute.find(attribute.id)
    yaml_attribute.screens[:overview_bulk] = { 'ticket.agent' => { nulloption: true } }

    expect { yaml_attribute.save! }.not_to raise_error
    expect(ObjectManager::Attribute.find(attribute.id).screens[:overview_bulk]['ticket.agent'][:nulloption]).to be(true)
    expect(ObjectManager::Attribute.find(attribute.id).data_option).to eq(attribute_data_option)
  end

  it 'converts the columns to jsonb', system_init_done: true do
    expect { migrate }
      .to change { column_type('object_manager_attributes', 'data_option') }.from(:text).to(:jsonb)
      .and change { column_type('core_workflows', 'perform') }.from(:text).to(:jsonb)
  end

  it 'keeps the values', :aggregate_failures, system_init_done: true do
    migrate

    migrated_attribute = ObjectManager::Attribute.find(attribute.id)
    migrated_workflow  = CoreWorkflow.find(workflow.id)

    expect(migrated_attribute.data_option).to eq(attribute_data_option)
    expect(migrated_attribute.screens).to eq(attribute_screens)
    expect(migrated_attribute.data_option_new).to eq({})
    expect(migrated_attribute.data_option[:relation]).to eq('TicketState')
    expect(migrated_workflow.perform).to eq(workflow_perform)
  end

  it 'converts boolean and integer option keys to strings', :aggregate_failures, system_init_done: true do
    migrate

    migrated_boolean = ObjectManager::Attribute.find(boolean_attribute.id)
    migrated_select  = ObjectManager::Attribute.find(select_attribute.id)

    expect(migrated_boolean.data_option[:options]).to eq({ 'true' => 'yes', 'false' => 'no' })
    expect(migrated_boolean.data_option[:default]).to be(true)
    expect(migrated_select.data_option[:options]).to eq({ '1' => 'one', '2' => 'two' })
    expect(migrated_select.data_option[:default]).to eq(1)
  end

  it 'converts custom sorted hash options to an array in stored order', system_init_done: true do
    migrate

    expect(ObjectManager::Attribute.find(sorted_attribute.id).data_option[:options]).to eq([{ 'name' => 'Last', 'value' => 'zz' }, { 'name' => 'First', 'value' => 'a' }])
  end

  it 'fails naming the row that cannot be converted', system_init_done: true do
    ActiveRecord::Base.connection.update("UPDATE object_manager_attributes SET data_option = 'no: [yaml' WHERE id = #{select_attribute.id}")

    expect { migrate }.to raise_error(StandardError, %r{object_manager_attributes.data_option id=#{select_attribute.id} cannot be converted})
  end
end

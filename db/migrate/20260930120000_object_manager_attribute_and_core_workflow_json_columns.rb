# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ObjectManagerAttributeAndCoreWorkflowJsonColumns < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    convert_object_manager_attributes
    convert_core_workflows
  end

  private

  def convert_object_manager_attributes
    %w[screens data_option data_option_new].each do |column|
      values = yaml_values(:object_manager_attributes, column)
      values.each_value { |value| customsort_options_to_array(value) } if column != 'screens'

      add_column :object_manager_attributes, "#{column}_json", :jsonb, null: false, default: {}
      write_json_values(:object_manager_attributes, "#{column}_json", values)
      remove_column :object_manager_attributes, column
      rename_column :object_manager_attributes, "#{column}_json", column
    end

    ObjectManager::Attribute.reset_column_information
  end

  def convert_core_workflows
    %w[preferences condition_saved condition_selected perform].each do |column|
      values = yaml_values(:core_workflows, column)

      add_column :core_workflows, "#{column}_json", :jsonb, null: false, default: {}
      write_json_values(:core_workflows, "#{column}_json", values)
      remove_column :core_workflows, column
      rename_column :core_workflows, "#{column}_json", column
    end

    CoreWorkflow.reset_column_information
  end

  # the YAML of the store columns cannot be converted inside the database, earlier
  # migrations of the same run may already have written JSON into the text columns
  def yaml_values(table, column)
    select_rows("SELECT id, #{quote_column_name(column)} FROM #{quote_table_name(table)}").to_h do |id, raw|
      [id, yaml_value(table, column, id, raw)]
    end
  end

  # custom sorted hash options would lose their order in the jsonb column, the admin UI stores them as array
  def customsort_options_to_array(data_option)
    return if data_option['customsort'] != 'on'
    return if !data_option['options'].is_a?(Hash)

    data_option['options'] = data_option['options'].map { |value, name| { 'name' => name, 'value' => value.to_s } }
  end

  def yaml_value(table, column, id, raw)
    return {} if raw.blank?

    value = raw.lstrip.start_with?('---') ? YAML.unsafe_load(raw) : JSON.parse(raw)
    return {} if value.nil?
    raise "unexpected #{value.class}" if !value.is_a?(Hash)

    value.with_indifferent_access
  rescue => e
    raise "#{table}.#{column} id=#{id} cannot be converted: #{e.message}"
  end

  def write_json_values(table, column, values)
    type = ActiveRecord::Type::IndifferentJson.new

    values.each_slice(500) do |slice|
      rows = slice.map { |id, value| "(#{id.to_i}, #{quote(type.serialize(value))}::jsonb)" }.join(', ')

      update "UPDATE #{quote_table_name(table)} SET #{quote_column_name(column)} = data.value FROM (VALUES #{rows}) AS data(id, value) WHERE #{quote_table_name(table)}.id = data.id"
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class MigrationHelper

=begin

  MigrationHelper.rename_custom_object_attribute('Organization', 'vip')

=end

  def self.rename_custom_object_attribute(object, name)
    return if !custom_object_attribute(object, name)

    sanitized_name = "_#{name}"
    custom_object_attribute(object, name).update!(name: sanitized_name)

    rename_table_column(object.constantize, name, sanitized_name)
  end

=begin

This function renames reserved words for all models:

Renames 'data' for all models to '_data':

  MigrationHelper.rename_custom_object_attribute_reserved('data')

Renames 'data' for model 'Ticket' to '_data':

  MigrationHelper.rename_custom_object_attribute_reserved('data', models: %w[Ticket])

Returns:

  true

=end

  def self.rename_custom_object_attribute_reserved(name, models: [])
    filtered = ObjectManager.list_objects.filter { |model_name| models.blank? || models.include?(model_name) }

    # pre checks to ensure rename is ok before any mutation
    filtered.each do |model_name|

      # This is a counter check to ensure that you do not rename something which is not reserved.
      rename_unnecessary = ObjectManager::Attribute.for_object(model_name).new(name: name).check_name(raise_error: false)
      raise "Failed to rename '#{name}' because it is neither a global reserved word nor a reserved word for object #{model_name}!" if rename_unnecessary
    end

    filtered.each { |model_name| rename_custom_object_attribute(model_name, name) } # rubocop:disable Style/CombinableLoops

    true
  end

=begin

  object_attribute = MigrationHelper.custom_object_attribute('Organization', 'vip')

  returns ObjectManager::Attribute

=end

  def self.custom_object_attribute(object, name)
    ObjectManager::Attribute.get(object: object, name: name)
  end

=begin

  MigrationHelper.rename_table_column(Organization, 'vip', '_vip')

=end

  def self.rename_table_column(model, name, sanitized_name)
    return if ActiveRecord::Base.connection.columns(model.table_name).map(&:name).exclude?(name)

    ActiveRecord::Migration.rename_column(model.table_name.to_sym, name.to_sym, sanitized_name.to_sym)
    model.connection.schema_cache.clear!
    model.reset_column_information
  end
end

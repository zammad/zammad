# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

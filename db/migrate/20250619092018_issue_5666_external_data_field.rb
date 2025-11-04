# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Issue5666ExternalDataField < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    attributes = ObjectManager::Attribute.where(data_type: 'autocompletion_ajax_external_data_source')

    return if attributes.blank?

    attributes.each { update_single_attribute(it) }

    ApplicationModel.reset_column_information
  end

  private

  def update_single_attribute(attribute)
    klass = attribute.object_lookup.name.constantize

    # Simply update the value in database without triggering anything on the app side
    klass
      .where(attribute.name => nil)
      .update_all(attribute.name => {}) # rubocop:disable Rails/SkipsModelValidations

    ActiveRecord::Migration.change_column( # rubocop:disable Zammad/ExistsResetColumnInformation
      klass.table_name,
      attribute.name,
      :jsonb,
      default: {},
      null:    false,
    )
  end
end

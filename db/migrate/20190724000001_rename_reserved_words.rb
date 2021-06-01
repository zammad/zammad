# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class RenameReservedWords < ActiveRecord::Migration[5.1]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    models = ObjectManager.list_objects.map(&:underscore).map { |object| object.tr('_', '/') }.map(&:classify).map(&:constantize)

    reserved_words = %w[url icon initials avatar permission validate subscribe unsubscribe translate search]
    models.each do |model|

      reserved_words.each do |reserved_word|

        next if ActiveRecord::Base.connection.columns(model.table_name).map(&:name).exclude?(reserved_word)

        sanitized_name = "_#{reserved_word}"

        ActiveRecord::Migration.rename_column(model.table_name.to_sym, reserved_word.to_sym, sanitized_name.to_sym)
        model.reset_column_information

        attribute = ObjectManager::Attribute.get(
          object: model.to_app_model,
          name:   reserved_word,
        )
        next if !attribute

        attribute.update!(name: sanitized_name)
      end
    end
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::ChecksAttributeValuesAndLength
  extend ActiveSupport::Concern

  included do
    before_create :check_attribute_values_and_length
    before_update :check_attribute_values_and_length
  end

=begin

1) check string/varchar size and cut them if needed

2) check string for null byte \u0000 and remove it

=end

  def check_attribute_values_and_length
    columns = self.class.columns_hash
    attributes.each do |name, value|
      next if !value.instance_of?(String)

      column = columns[name]
      next if !column

      if column.type == :binary
        self[name].force_encoding('BINARY')
      end

      next if value.blank?

      # strip null byte chars (postgresql will complain about it)
      if column.type == :text && Rails.application.config.db_null_byte == false
        self[name].delete!("\u0000")
      end

      # for varchar check length and replace null bytes
      limit = column.limit
      if limit
        current_length = value.length
        if limit < current_length
          logger.warn "WARNING: cut string because of database length #{self.class}.#{name}(#{limit} but is #{current_length}:#{value})"
          self[name] = value[0, limit]
        end

        # strip null byte chars (postgresql will complain about it)
        if Rails.application.config.db_null_byte == false
          self[name].delete!("\u0000")
        end
      end

      # strip 4 bytes utf8 chars if needed (mysql/mariadb will complain it)
      next if self[name].blank?

      self[name] = self[name].utf8_to_3bytesutf8
    end
    true
  end
end

# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::ChecksAttributeLength
  extend ActiveSupport::Concern

  included do
    before_create :check_attribute_length
    before_update :check_attribute_length
  end

=begin

check string/varchar size and cut them if needed

=end

  def check_attribute_length
    attributes.each { |attribute|
      next if !self[ attribute[0] ]
      next if !self[ attribute[0] ].instance_of?(String)
      next if self[ attribute[0] ].empty?
      column = self.class.columns_hash[ attribute[0] ]
      next if !column
      limit = column.limit
      if column && limit
        current_length = attribute[1].to_s.length
        if limit < current_length
          logger.warn "WARNING: cut string because of database length #{self.class}.#{attribute[0]}(#{limit} but is #{current_length}:#{attribute[1]})"
          self[ attribute[0] ] = attribute[1][ 0, limit ]
        end
      end

      # strip 4 bytes utf8 chars if needed
      if column && self[ attribute[0] ]
        self[attribute[0]] = self[ attribute[0] ].utf8_to_3bytesutf8
      end
    }
    true
  end
end

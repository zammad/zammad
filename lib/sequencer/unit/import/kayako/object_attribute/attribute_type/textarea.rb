# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Textarea < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Base
  private

  def data_type_specific_options
    {
      type:      'textarea',
      maxlength: ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2' ? 2_000 : 65_535,
    }
  end
end

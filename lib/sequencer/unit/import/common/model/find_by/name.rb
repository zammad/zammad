# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::FindBy::Name < Sequencer::Unit::Import::Common::Model::FindBy::SameNamedAttribute
  def lookup_find_by(attribute, value)
    quoted_column = ActiveRecord::Base.connection.quote_column_name(attribute)
    model_class.find_by("LOWER(#{quoted_column}) = LOWER(?)", value)
  end
end

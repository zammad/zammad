# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Request < Sequencer::Unit::Common::Provider::Attribute
  class GenericField < Sequencer::Unit::Import::Kayako::Request::Generic
    def params
      super.merge(
        include: 'field_option,locale_field',
      )
    end
  end
end

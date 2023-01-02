# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Request < Sequencer::Unit::Common::Provider::Attribute
  class Organization < Sequencer::Unit::Import::Kayako::Request::Generic
    def params
      super.merge(
        include: 'organization_field,field_option,locale_field,identity_domain',
      )
    end
  end
end

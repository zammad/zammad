# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Request < Sequencer::Unit::Common::Provider::Attribute
  class User < Sequencer::Unit::Import::Kayako::Request::Generic
    def params
      super.merge(
        include: 'user_field,field_option,locale_field,identity_email,identify_phone,identity_twitter,identity_facebook,role',
      )
    end
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        class Request < Sequencer::Unit::Common::Provider::Attribute
          class Organization < Sequencer::Unit::Import::Kayako::Request::Generic
            def params
              super.merge(
                include: 'organization_field,field_option,locale_field,identity_domain',
              )
            end
          end
        end
      end
    end
  end
end

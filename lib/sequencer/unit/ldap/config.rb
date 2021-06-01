# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'import/ldap'

class Sequencer
  class Unit
    module Ldap
      class Config < Sequencer::Unit::Common::Provider::Fallback

        provides :ldap_config

        private

        def ldap_config
          ::Import::Ldap.config
        end
      end
    end
  end
end

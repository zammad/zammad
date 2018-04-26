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

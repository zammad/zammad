require 'import/ldap'

class Sequencer
  class Unit
    module Ldap
      class Config < Sequencer::Unit::Common::FallbackProvider
        provides :ldap_config

        private

        def fallback
          ::Import::Ldap.config
        end
      end
    end
  end
end

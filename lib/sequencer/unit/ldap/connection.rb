require 'ldap'

class Sequencer
  class Unit
    module Ldap
      class Connection < Sequencer::Unit::Common::FallbackProvider
        uses :ldap_config
        provides :ldap_connection

        private

        def fallback
          ::Ldap.new(ldap_config)
        end
      end
    end
  end
end

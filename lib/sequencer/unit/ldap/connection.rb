# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'ldap'

class Sequencer
  class Unit
    module Ldap
      class Connection < Sequencer::Unit::Common::Provider::Fallback

        uses :ldap_config
        provides :ldap_connection

        private

        def ldap_connection
          ::Ldap.new(ldap_config)
        end
      end
    end
  end
end

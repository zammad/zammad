require 'ldap'
require 'import/ldap'

class Sequencer
  class Unit
    module Ldap
      class Connection < Sequencer::Unit::Base
        uses :ldap_config
        provides :ldap_connection

        def process
          return if state.provided?(:ldap_connection)

          state.provide(:ldap_connection) do
            config   = ldap_config
            config ||= ::Import::Ldap.config

            ::Ldap.new(config)
          end
        end
      end
    end
  end
end

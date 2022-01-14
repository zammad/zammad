# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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

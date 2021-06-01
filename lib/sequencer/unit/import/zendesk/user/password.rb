# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module User
          class Password < Sequencer::Unit::Common::Provider::Named

            uses :initiator

            private

            def password
              # set the used import key as the admin password
              # since we have no other confidential value
              # that is known to Zammad and the User
              return Setting.get('import_zendesk_endpoint_key') if initiator

              # otherwise set an empty password so the user
              # has to re-set a new password for Zammad
              ''
            end
          end
        end
      end
    end
  end
end

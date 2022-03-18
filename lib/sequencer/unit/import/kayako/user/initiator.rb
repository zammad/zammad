# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module User
          class Initiator < Sequencer::Unit::Common::Provider::Named

            uses :login

            private

            def initiator
              return false if login.blank?

              login == Setting.get('import_kayako_endpoint_username')
            end
          end
        end
      end
    end
  end
end

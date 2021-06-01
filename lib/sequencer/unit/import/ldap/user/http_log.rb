# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          class HttpLog < Import::Common::Model::HttpLog
            private

            def facility
              'ldap'
            end
          end
        end
      end
    end
  end
end
